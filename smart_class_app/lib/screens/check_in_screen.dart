import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

import '../data/app_database.dart';
import '../services/location_service.dart';
import 'qr_scanner_screen.dart';

class CheckInScreen extends StatefulWidget {
  const CheckInScreen({super.key});

  @override
  State<CheckInScreen> createState() => _CheckInScreenState();
}

class _CheckInScreenState extends State<CheckInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _studentIdController = TextEditingController();
  final _previousTopicController = TextEditingController();
  final _expectedTopicController = TextEditingController();

  final DateTime _checkInTimestamp = DateTime.now();

  LocationSnapshot? _location;
  String? _locationError;
  String? _qrCode;
  int _moodBeforeClass = 3;
  bool _isLocating = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _captureLocation();
  }

  @override
  void dispose() {
    _studentIdController.dispose();
    _previousTopicController.dispose();
    _expectedTopicController.dispose();
    super.dispose();
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

  Future<void> _submitCheckIn() async {
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
      await AppDatabase.instance.insertCheckIn(
        studentId: _studentIdController.text.trim(),
        checkInTimestamp: _checkInTimestamp,
        checkInLatitude: _location!.latitude,
        checkInLongitude: _location!.longitude,
        checkInQrCode: _qrCode!,
        previousTopic: _previousTopicController.text.trim(),
        expectedTopic: _expectedTopicController.text.trim(),
        moodBeforeClass: _moodBeforeClass,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Check-in saved successfully.'), backgroundColor: Colors.green),
      );
      Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;
      _showErrorSnackBar('Unable to save check-in. Please try again.');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red.shade600),
    );
  }

  String _moodEmoji(int mood) {
    switch (mood) {
      case 1: return '😡';
      case 2: return '🙁';
      case 3: return '😐';
      case 4: return '🙂';
      case 5: return '😄';
      default: return '😐';
    }
  }

  String _moodLabel(int mood) {
    switch (mood) {
      case 1: return 'Very negative';
      case 2: return 'Negative';
      case 3: return 'Neutral';
      case 4: return 'Positive';
      case 5: return 'Very positive';
      default: return 'Neutral';
    }
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, color: AppColors.primary, size: 24),
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
      appBar: AppBar(title: const Text('Start Class Check-in')),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: FilledButton(
            onPressed: _isSaving ? null : _submitCheckIn,
            child: _isSaving 
              ? const SizedBox(
                  width: 24, height: 24, 
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                )
              : const Text('Submit Check-in', style: TextStyle(fontSize: 16)),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader('System Verification', Icons.verified_user_outlined),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.access_time),
                      title: const Text('Check-in Time'),
                      subtitle: Text(_checkInTimestamp.toLocal().toString().split('.').first),
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

              _buildSectionHeader('Student Details', Icons.person_outline),
              TextFormField(
                controller: _studentIdController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Student ID',
                  prefixIcon: Icon(Icons.badge_outlined),
                  hintText: 'Enter your student ID',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return 'Student ID is required.';
                  return null;
                },
              ),

              _buildSectionHeader('Pre-Class Reflection', Icons.edit_note),
              TextFormField(
                controller: _previousTopicController,
                decoration: const InputDecoration(
                  labelText: 'Previous Class Topic',
                  prefixIcon: Icon(Icons.history_edu),
                  hintText: 'What did we discuss last time?',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return 'Please enter previous class topic.';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _expectedTopicController,
                decoration: const InputDecoration(
                  labelText: 'Expected Topic Today',
                  prefixIcon: Icon(Icons.lightbulb_outline),
                  hintText: 'What do you expect to learn?',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return 'Please enter expected topic.';
                  return null;
                },
              ),
              
              const SizedBox(height: 24),
              const Text(
                'Mood Before Class',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                  child: Column(
                    children: [
                      Text(
                        '${_moodEmoji(_moodBeforeClass)} ${_moodLabel(_moodBeforeClass)}',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 12),
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          activeTrackColor: AppColors.primary,
                          thumbColor: AppColors.primary,
                          overlayColor: AppColors.primary.withOpacity(0.2),
                          valueIndicatorTextStyle: const TextStyle(color: Colors.white),
                        ),
                        child: Slider(
                          value: _moodBeforeClass.toDouble(),
                          min: 1,
                          max: 5,
                          divisions: 4,
                          label: _moodEmoji(_moodBeforeClass),
                          onChanged: (value) {
                            setState(() => _moodBeforeClass = value.round());
                          },
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                              Text('😡', style: TextStyle(fontSize: 16)),
                              Text('😄', style: TextStyle(fontSize: 16)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
