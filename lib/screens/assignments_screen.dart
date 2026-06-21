import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../theme/app_theme.dart';
import '../services/lms_service.dart';
import '../models/assignment.dart';
import '../models/course.dart';

class AssignmentsScreen extends StatefulWidget {
  const AssignmentsScreen({super.key});

  @override
  State<AssignmentsScreen> createState() => _AssignmentsScreenState();
}

class _AssignmentsScreenState extends State<AssignmentsScreen> {
  List<Course> _courses = [];
  List<Assignment> _assignments = [];
  Course? _selected;
  bool _loadingCourses = true;
  bool _loadingAssignments = false;
  late LmsService _svc;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    const storage = FlutterSecureStorage();
    final cookie = await storage.read(key: 'lms_cookie') ?? '';
    _svc = LmsService(cookie);
    try {
      final courses = await _svc.getCourses();
      if (mounted) setState(() { _courses = courses; _loadingCourses = false; });
    } catch (_) {
      if (mounted) setState(() => _loadingCourses = false);
    }
  }

  Future<void> _loadAssignments(Course course) async {
    setState(() { _selected = course; _loadingAssignments = true; });
    try {
      final a = await _svc.getAssignments(course.id);
      a.sort((x, y) => x.deadline.compareTo(y.deadline));
      if (mounted) setState(() { _assignments = a; _loadingAssignments = false; });
    } catch (_) {
      if (mounted) setState(() => _loadingAssignments = false);
    }
  }

  Future<void> _upload(Assignment a) async {
    final result = await FilePicker.platform.pickFiles(type: FileType.any);
    if (result == null || result.files.single.path == null) return;
    final path = result.files.single.path!;
    final name = result.files.single.name;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Uploading $name...', style: GoogleFonts.outfit()),
        backgroundColor: AppTheme.card),
    );

    final ok = await _svc.uploadAssignment(_selected!.id, a.number.toString(), path, name);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? '✓ Uploaded successfully' : '✗ Upload failed', style: GoogleFonts.outfit()),
        backgroundColor: ok ? AppTheme.success : AppTheme.danger,
      ),
    );
    if (ok) _loadAssignments(_selected!);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: FadeInDown(child: Text('Assignments', style: GoogleFonts.outfit(
                color: AppTheme.textPrimary, fontSize: 28, fontWeight: FontWeight.w700,
              ))),
            ),
            const SizedBox(height: 16),
            _buildCourseChips(),
            const SizedBox(height: 8),
            Expanded(child: _buildAssignmentList()),
          ],
        ),
      ),
    );
  }

  Widget _buildCourseChips() {
    if (_loadingCourses) return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: LinearProgressIndicator(color: AppTheme.accent),
    );
    return SizedBox(
      height: 44,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _courses.length,
        itemBuilder: (_, i) => FadeInLeft(
          delay: Duration(milliseconds: i * 50),
          child: Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => _loadAssignments(_courses[i]),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: _selected?.id == _courses[i].id ? AppTheme.accent : AppTheme.card,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: _selected?.id == _courses[i].id ? AppTheme.accent : AppTheme.cardLight,
                  ),
                ),
                child: Text(
                  _courses[i].name.length > 20
                      ? '${_courses[i].name.substring(0, 20)}...'
                      : _courses[i].name,
                  style: GoogleFonts.outfit(
                    color: _selected?.id == _courses[i].id ? Colors.white : AppTheme.textSecondary,
                    fontSize: 12, fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAssignmentList() {
    if (_selected == null) return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.touch_app_rounded, color: AppTheme.textSecondary.withValues(alpha: 0.4), size: 56),
        const SizedBox(height: 12),
        Text('Select a course', style: GoogleFonts.outfit(color: AppTheme.textSecondary)),
      ]),
    );
    if (_loadingAssignments) return const Center(child: CircularProgressIndicator(color: AppTheme.accent));
    if (_assignments.isEmpty) return Center(child: Text('No assignments', style: GoogleFonts.outfit(color: AppTheme.textSecondary)));
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _assignments.length,
      itemBuilder: (_, i) => FadeInUp(
        delay: Duration(milliseconds: i * 70),
        child: _assignmentCard(_assignments[i]),
      ),
    );
  }

  Widget _assignmentCard(Assignment a) {
    Color statusColor;
    if (a.submitted) statusColor = AppTheme.success;
    else if (a.isOverdue) statusColor = AppTheme.danger;
    else if (a.isDueSoon) statusColor = AppTheme.warning;
    else statusColor = AppTheme.accent;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor.withValues(alpha: 0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text('${a.number}. ${a.title}', style: GoogleFonts.outfit(
              color: AppTheme.textPrimary, fontWeight: FontWeight.w600, fontSize: 15,
            ))),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(a.statusLabel, style: GoogleFonts.outfit(
                color: statusColor, fontSize: 11, fontWeight: FontWeight.w600,
              )),
            ),
          ]),
          const SizedBox(height: 8),
          Row(children: [
            Icon(Icons.schedule_rounded, size: 14, color: AppTheme.textSecondary),
            const SizedBox(width: 4),
            Text(
              '${a.deadline.day}/${a.deadline.month}/${a.deadline.year} at '
              '${a.deadline.hour.toString().padLeft(2, '0')}:${a.deadline.minute.toString().padLeft(2, '0')}',
              style: GoogleFonts.outfit(color: AppTheme.textSecondary, fontSize: 12),
            ),
            if (a.marks.isNotEmpty && a.marks != '---') ...[
              const SizedBox(width: 12),
              Icon(Icons.grade_rounded, size: 14, color: AppTheme.gold),
              const SizedBox(width: 4),
              Text(a.marks, style: GoogleFonts.outfit(color: AppTheme.gold, fontSize: 12)),
            ],
          ]),
          if (!a.submitted && !a.isOverdue) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _upload(a),
                icon: const Icon(Icons.upload_file_rounded, size: 18),
                label: Text('Upload Submission', style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.accent,
                  side: BorderSide(color: AppTheme.accent.withValues(alpha: 0.5)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          ],
        ]),
      ),
    );
  }
}
