import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../theme/app_theme.dart';
import '../services/cms_service.dart';
import '../models/attendance.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  List<AttendanceRecord> _records = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    const storage = FlutterSecureStorage();
    final cookie = await storage.read(key: 'cms_cookie') ?? '';
    try {
      final records = await CmsService(cookie).getAttendance();
      if (mounted)
        setState(() {
          _records = records;
          _loading = false;
        });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          color: AppTheme.accent,
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                  child: FadeInDown(
                    child: Text(
                      'Attendance',
                      style: GoogleFonts.outfit(
                        color: AppTheme.textPrimary,
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
              if (_loading)
                const SliverFillRemaining(
                  child: Center(
                    child: CircularProgressIndicator(color: AppTheme.accent),
                  ),
                )
              else if (_records.isEmpty)
                SliverFillRemaining(
                  child: Center(
                    child: Text(
                      'No attendance data',
                      style: GoogleFonts.outfit(color: AppTheme.textSecondary),
                    ),
                  ),
                )
              else ...[
                if (_records.any((r) => r.isCritical))
                  SliverToBoxAdapter(
                    child: FadeIn(child: _buildWarningBanner()),
                  ),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (_, i) => FadeInUp(
                      delay: Duration(milliseconds: i * 80),
                      child: _attendanceCard(_records[i]),
                    ),
                    childCount: _records.length,
                  ),
                ),
              ],
              const SliverToBoxAdapter(child: SizedBox(height: 20)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWarningBanner() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.danger.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.danger.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.warning_rounded, color: AppTheme.danger, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Attendance below 75% in one or more courses!',
                style: GoogleFonts.outfit(
                  color: AppTheme.danger,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _attendanceCard(AttendanceRecord r) {
    final color = r.isCritical
        ? AppTheme.danger
        : r.isWarning
        ? AppTheme.warning
        : AppTheme.success;
    final pct = (r.percentage / 100).clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            CircularPercentIndicator(
              radius: 36,
              lineWidth: 5,
              percent: pct,
              center: Text(
                '${r.percentage.toStringAsFixed(0)}%',
                style: GoogleFonts.outfit(
                  color: color,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              progressColor: color,
              backgroundColor: color.withValues(alpha: 0.15),
              circularStrokeCap: CircularStrokeCap.round,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    r.course,
                    style: GoogleFonts.outfit(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _pill(
                        Icons.check_circle_outline,
                        '${r.present} present',
                        AppTheme.success,
                      ),
                      const SizedBox(width: 8),
                      _pill(
                        Icons.cancel_outlined,
                        '${r.total - r.present} absent',
                        AppTheme.danger,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pill(IconData icon, String text, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 3),
        Text(
          text,
          style: GoogleFonts.outfit(
            color: AppTheme.textSecondary,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}
