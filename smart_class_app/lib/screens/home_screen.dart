import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../data/app_database.dart';
import '../models/class_session.dart';
import '../widgets/action_card.dart';
import '../widgets/detail_row.dart';
import '../widgets/summary_card.dart';
import 'check_in_screen.dart';
import 'finish_class_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isLoading = true;
  List<ClassSession> _sessions = const [];

  @override
  void initState() {
    super.initState();
    _loadSessions();
  }

  Future<void> _loadSessions() async {
    setState(() => _isLoading = true);
    try {
      final sessions = await AppDatabase.instance.getAllSessions();
      if (!mounted) return;
      setState(() => _sessions = sessions);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _openCheckIn() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const CheckInScreen()),
    );
    if (result == true) await _loadSessions();
  }

  Future<void> _openFinishClass() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const FinishClassScreen()),
    );
    if (result == true) await _loadSessions();
  }

  String _formatDateTime(DateTime value) {
    final local = value.toLocal();
    final twoDigitsMinute = local.minute.toString().padLeft(2, '0');
    return '${local.year}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')} '
        '${local.hour.toString().padLeft(2, '0')}:$twoDigitsMinute';
  }

  String _getMoodText(int mood) {
    switch (mood) {
      case 1: return '😡 Very negative';
      case 2: return '🙁 Negative';
      case 3: return '😐 Neutral';
      case 4: return '🙂 Positive';
      case 5: return '😄 Very positive';
      default: return '😐 Unknown';
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeCount = _sessions.where((session) => !session.isCompleted).length;
    final completedCount = _sessions.where((session) => session.isCompleted).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Class Dashboard', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadSessions,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Session Summary',
                            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              SummaryCard(
                                title: 'Active',
                                count: activeCount.toString(),
                                icon: Icons.pending_actions,
                                color: AppColors.warning,
                              ),
                              const SizedBox(width: 12),
                              SummaryCard(
                                title: 'Completed',
                                count: completedCount.toString(),
                                icon: Icons.task_alt,
                                color: AppColors.success,
                              ),
                            ],
                          ),
                          const SizedBox(height: 32),
                          const Text(
                            'Quick Actions',
                            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: ActionCard(
                                  title: 'Class Check-in',
                                  icon: Icons.login,
                                  color: AppColors.primary,
                                  onTap: _openCheckIn,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: ActionCard(
                                  title: 'Finish Class',
                                  icon: Icons.logout,
                                  color: AppColors.secondary,
                                  onTap: _openFinishClass,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 32),
                          const Text(
                            'Recent Activity',
                            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 12),
                        ],
                      ),
                    ),
                  ),
                  _sessions.isEmpty
                      ? SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 40),
                            child: Center(
                              child: Column(
                                children: [
                                  Icon(Icons.history_toggle_off, size: 64, color: Colors.grey.shade300),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No records yet.',
                                    style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Start by checking in to a class.',
                                    style: TextStyle(color: Colors.grey.shade500),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                      : SliverPadding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final session = _sessions[index];
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  child: Theme(
                                    data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                                    child: ExpansionTile(
                                      tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                      leading: Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: session.isCompleted
                                              ? AppColors.success.withOpacity(0.1)
                                              : AppColors.warning.withOpacity(0.1),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          session.isCompleted ? Icons.check : Icons.hourglass_empty,
                                          color: session.isCompleted ? AppColors.success : AppColors.warning,
                                        ),
                                      ),
                                      title: Text(
                                        'Student ID: ${session.studentId}',
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                      subtitle: Text(
                                        'Date: ${_formatDateTime(session.checkInTimestamp)}',
                                        style: TextStyle(color: Colors.grey.shade600),
                                      ),
                                      children: [
                                        const Divider(),
                                        Padding(
                                          padding: const EdgeInsets.all(16),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              DetailRow(icon: Icons.history, label: 'Previous Topic', value: session.previousTopic),
                                              DetailRow(icon: Icons.lightbulb_outline, label: 'Expected Topic', value: session.expectedTopic),
                                              DetailRow(icon: Icons.mood, label: 'Mood', value: _getMoodText(session.moodBeforeClass)),
                                              if (session.isCompleted) ...[
                                                const SizedBox(height: 12),
                                                DetailRow(icon: Icons.school_outlined, label: 'Learned', value: session.learnedToday!),
                                                DetailRow(icon: Icons.feedback_outlined, label: 'Feedback', value: session.feedback!),
                                                const SizedBox(height: 8),
                                                Text(
                                                  'Out: ${_formatDateTime(session.checkOutTimestamp!)}',
                                                  style: TextStyle(
                                                      color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                              childCount: _sessions.length,
                            ),
                          ),
                        ),
                  const SliverToBoxAdapter(child: SizedBox(height: 40)),
                ],
              ),
            ),
    );
  }
}