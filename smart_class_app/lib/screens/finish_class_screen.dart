import 'package:flutter/material.dart';

import '../data/app_database.dart';
import '../models/class_session.dart';
import '../services/location_service.dart';
import 'qr_scanner_screen.dart';

class FinishClassScreen extends StatefulWidget {
  const FinishClassScreen({super.key});

  @override
  State<FinishClassScreen> createState() => _FinishClassScreenState();
}

class _FinishClassScreenState extends State<FinishClassScreen> {
  final _formKey = GlobalKey<FormState>();
  final _learnedTodayController = TextEditingController();
  final _feedbackController = TextEditingController();

  final DateTime _checkOutTimestamp = DateTime.now();

  List<ClassSession> _activeSessions = const [];
  int? _selectedSessionId;
  LocationSnapshot? _location;
  String? _locationError;
  String? _qrCode;
  bool _isLoadingSessions = true;
  bool _isLocating = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadActiveSessions();
    _captureLocation();
  }

  @override
  void dispose() {
    _learnedTodayController.dispose();
    _feedbackController.dispose();
    super.dispose();
  }

  Future<void> _loadActiveSessions() async {
    setState(() => _isLoadingSessions = true);
    try {
      final sessions = await AppDatabase.instance.getActiveSessions();
      if (!mounted) return;
      setState(() {
        _activeSessions = sessions;
        _selectedSessionId = sessions.isNotEmpty ? sessions.first.id : null;
      });
    } finally {
      if (mounted) setState(() => _isLoadingSessions = false);
    }
  }

  Future<void> _captureLocation() async {
    setState(() {
      _isLocating = true;
      _locationError = null;
    });

    try {
      final result = await LocationService().captureCurrentLocation();
      if (!mounted) return;
      setState(() => _location = result);
    } catch (error) {
      if (!mounted) return;
      setState(() => _locationError = error.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLocating = false);
    }
  }

  Future<void> _scanQrCode() async {
    final code = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const QrScannerScreen()),
    );

    if (!mounted || code == null || code.isEmpty) return;
    setState(() => _qrCode = code);
  }

  Future<void> _submitFinishClass() async {
    if (_selectedSessionId == null) {
      _showErrorSnackBar('No active check-in available to finish.');
      return;
    }

    final isFormValid = _formKey.currentState?.validate() ?? false;
    if (!isFormValid) return;

    if (_location == null) {
      _showErrorSnackBar('Please wait for GPS location to be captured.');
      return;
    }

    if (_qrCode == null) {
      _showErrorSnackBar('Please scan class QR code before submitting.');
      return;
    }

    setState(() => _isSaving = true);

    try {
      await AppDatabase.instance.completeCheckOut(
        sessionId: _selectedSessionId!,
        checkOutTimestamp: _checkOutTimestamp,
        checkOutLatitude: _location!.latitude,
        checkOutLongitude: _location!.longitude,
        checkOutQrCode: _qrCode!,
        learnedToday: _learnedTodayController.text.trim(),
        feedback: _feedbackController.text.trim(),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Class completed successfully.'), backgroundColor: Colors.green),
      );
      Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;
      _showErrorSnackBar('Unable to save class completion. Please try again.');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red.shade600),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, color: const Color(0xFF0D9488), size: 24),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Finish Class Session')),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: FilledButton(
             style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF0D9488),
            ),
            onPressed: (_isSaving || _activeSessions.isEmpty) ? null : _submitFinishClass,
            child: _isSaving 
              ? const SizedBox(
                  width: 24, height: 24, 
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                )
              : const Text('Complete Class', style: TextStyle(fontSize: 16)),
          ),
        ),
      ),
      body: _isLoadingSessions
          ? const Center(child: CircularProgressIndicator())
          : _activeSessions.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle_outline, size: 80, color: Colors.grey.shade400),
                        const SizedBox(height: 24),
                        const Text(
                          'No Active Classes',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'You do not have any active check-in sessions to finish.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                        ),
                        const SizedBox(height: 24),
                        OutlinedButton.icon(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.arrow_back),
                          label: const Text('Go Back'),
                        ),
                      ],
                    ),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionHeader('Session Details', Icons.assignment_ind_outlined),
                        DropdownButtonFormField<int>(
                          value: _selectedSessionId,
                          decoration: const InputDecoration(
                            labelText: 'Active check-in session',
                            prefixIcon: Icon(Icons.person),
                          ),
                          icon: const Icon(Icons.expand_more),
                          items: _activeSessions.map((session) {
                            final time = session.checkInTimestamp.toLocal();
                            return DropdownMenuItem<int>(
                              value: session.id,
                              child: Text(
                                '${session.studentId}  ${time.hour}:${time.minute.toString().padLeft(2, '0')}',
                              ),
                            );
                          }).toList(growable: false),
                          onChanged: (value) => setState(() => _selectedSessionId = value),
                          validator: (value) => value == null ? 'Please select a session.' : null,
                        ),

                        _buildSectionHeader('System Verification', Icons.verified_user_outlined),
                        Card(
                          child: Column(
                            children: [
                              ListTile(
                                leading: const Icon(Icons.access_time),
                                title: const Text('Check-out Time'),
                                subtitle: Text(_checkOutTimestamp.toLocal().toString().split('.').first),
                              ),
                              const Divider(height: 1),
                              ListTile(
                                leading: const Icon(Icons.location_on_outlined),
                                title: const Text('GPS Location'),
                                subtitle: _isLocating
                                    ? const Text('Capturing location...')
                                    : _location != null
                                        ? Text('Lat: ${_location!.latitude.toStringAsFixed(4)}, Lng: ${_location!.longitude.toStringAsFixed(4)}')
                                        : Text(_locationError ?? 'Failed to capture.'),
                                trailing: IconButton(
                                  icon: const Icon(Icons.refresh),
                                  onPressed: _isLocating ? null : _captureLocation,
                                  tooltip: 'Recapture Location',
                                ),
                              ),
                              const Divider(height: 1),
                              ListTile(
                                leading: const Icon(Icons.qr_code_scanner),
                                title: const Text('Class QR Code'),
                                subtitle: Text(_qrCode ?? 'Not scanned yet'),
                                trailing: FilledButton.tonal(
                                  onPressed: _scanQrCode,
                                  style: FilledButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 16),
                                    visualDensity: VisualDensity.compact,
                                  ),
                                  child: const Text('Scan'),
                                ),
                              ),
                            ],
                          ),
                        ),

                        _buildSectionHeader('Post-Class Reflection', Icons.draw_outlined),
                        TextFormField(
                          controller: _learnedTodayController,
                          decoration: const InputDecoration(
                            labelText: 'What did you learn today?',
                            alignLabelWithHint: true,
                          ),
                          maxLines: 4,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) return 'Please detail what you learned.';
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _feedbackController,
                          decoration: const InputDecoration(
                            labelText: 'Feedback about class/instructor',
                            alignLabelWithHint: true,
                          ),
                          maxLines: 3,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) return 'Please provide class feedback.';
                            return null;
                          },
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
    );
  }
}
