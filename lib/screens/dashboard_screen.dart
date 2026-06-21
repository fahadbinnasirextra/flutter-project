import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../theme/app_theme.dart';
import '../services/lms_service.dart';
import '../models/assignment.dart';
import '../models/course.dart';
import 'login_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List<Assignment> _upcoming = [];
  bool _loading = true;
  String _enrollment = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    const storage = FlutterSecureStorage();
    final cookie = await storage.read(key: 'lms_cookie') ?? '';
    final prefs = await SharedPreferences.getInstance();
    _enrollment = prefs.getString('enrollment') ?? '';

    final svc = LmsService(cookie);
    List<Course> courses = [];
    try { courses = await svc.getCourses(); } catch (_) {}

    final List<Assignment> all = [];
    for (final c in courses) {
      try {
        final a = await svc.getAssignments(c.id);
        all.addAll(a);
      } catch (_) {}
    }

    all.sort((a, b) => a.deadline.compareTo(b.deadline));
    final upcoming = all.where((a) => !a.isOverdue && !a.submitted).toList();

    if (mounted) setState(() { _upcoming = upcoming; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft, end: Alignment.bottomCenter,
            colors: [Color(0xFF060D1A), AppTheme.primary],
          ),
        ),
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: _load,
            color: AppTheme.accent,
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: _buildHeader()),
                SliverToBoxAdapter(child: _buildStatCards()),
                SliverToBoxAdapter(child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                  child: Text('Upcoming Deadlines', style: GoogleFonts.outfit(
                    color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.w600,
                  )),
                )),
                if (_loading)
                  const SliverFillRemaining(child: Center(
                    child: CircularProgressIndicator(color: AppTheme.accent),
                  ))
                else if (_upcoming.isEmpty)
                  SliverToBoxAdapter(child: _buildEmpty())
                else
                  SliverList(delegate: SliverChildBuilderDelegate(
                    (ctx, i) => FadeInUp(
                      delay: Duration(milliseconds: i * 80),
                      child: _buildAssignmentCard(_upcoming[i]),
                    ),
                    childCount: _upcoming.length,
                  )),
                const SliverToBoxAdapter(child: SizedBox(height: 20)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Row(
        children: [
          FadeInDown(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Good ${_greeting()}', style: GoogleFonts.outfit(
                color: AppTheme.textSecondary, fontSize: 14,
              )),
              Text(_enrollment, style: GoogleFonts.outfit(
                color: AppTheme.textPrimary, fontSize: 20, fontWeight: FontWeight.w700,
              )),
            ],
          )),
          const Spacer(),
          FadeInDown(child: GestureDetector(
            onTap: _logout,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.card, borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.cardLight),
              ),
              child: const Icon(Icons.logout_rounded, color: AppTheme.textSecondary, size: 20),
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildStatCards() {
    final overdue = _upcoming.where((a) => a.isOverdue).length;
    final dueSoon = _upcoming.where((a) => a.isDueSoon).length;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Row(children: [
        Expanded(child: FadeInLeft(child: _statCard('Pending', _upcoming.length.toString(), Icons.pending_actions_rounded, AppTheme.accent))),
        const SizedBox(width: 12),
        Expanded(child: FadeInLeft(delay: const Duration(milliseconds: 100), child: _statCard('Due Soon', dueSoon.toString(), Icons.access_alarm_rounded, AppTheme.warning))),
        const SizedBox(width: 12),
        Expanded(child: FadeInLeft(delay: const Duration(milliseconds: 200), child: _statCard('Overdue', overdue.toString(), Icons.warning_amber_rounded, AppTheme.danger))),
      ]),
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 10),
          Text(value, style: GoogleFonts.outfit(color: color, fontSize: 28, fontWeight: FontWeight.w700)),
          Text(label, style: GoogleFonts.outfit(color: AppTheme.textSecondary, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildAssignmentCard(Assignment a) {
    final diff = a.deadline.difference(DateTime.now());
    final color = a.isDueVerySoon ? AppTheme.danger : a.isDueSoon ? AppTheme.warning : AppTheme.accent;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(children: [
          Container(
            width: 4, height: 50,
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(a.title, style: GoogleFonts.outfit(
                color: AppTheme.textPrimary, fontWeight: FontWeight.w600, fontSize: 15,
              )),
              const SizedBox(height: 4),
              Text(a.courseId, style: GoogleFonts.outfit(color: AppTheme.textSecondary, fontSize: 12)),
            ],
          )),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(_formatDuration(diff), style: GoogleFonts.outfit(
                  color: color, fontSize: 12, fontWeight: FontWeight.w600,
                )),
              ),
              const SizedBox(height: 4),
              Text('${a.deadline.day}/${a.deadline.month}', style: GoogleFonts.outfit(
                color: AppTheme.textSecondary, fontSize: 11,
              )),
            ],
          ),
        ]),
      ),
    );
  }

  Widget _buildEmpty() {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(children: [
        Icon(Icons.check_circle_outline_rounded, color: AppTheme.success, size: 64),
        const SizedBox(height: 16),
        Text('All caught up!', style: GoogleFonts.outfit(
          color: AppTheme.textPrimary, fontSize: 20, fontWeight: FontWeight.w600,
        )),
        const SizedBox(height: 8),
        Text('No upcoming deadlines', style: GoogleFonts.outfit(color: AppTheme.textSecondary)),
      ]),
    );
  }

  String _formatDuration(Duration d) {
    if (d.inDays > 0) return '${d.inDays}d left';
    if (d.inHours > 0) return '${d.inHours}h left';
    return '${d.inMinutes}m left';
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'morning,';
    if (h < 17) return 'afternoon,';
    return 'evening,';
  }

  Future<void> _logout() async {
    const storage = FlutterSecureStorage();
    await storage.deleteAll();
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (mounted) Navigator.pushReplacement(context,
      MaterialPageRoute(builder: (_) => const LoginScreen()));
  }
}
