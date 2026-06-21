import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html_parser;
import '../models/assignment.dart';
import '../models/course.dart';

class LmsService {
  static const _base = 'https://lms.bahria.edu.pk';
  final String cookie;
  LmsService(this.cookie);

  Future<List<Course>> getCourses() async {
    final resp = await http.get(
      Uri.parse('$_base/Student/Assignments.php'),
      headers: {'Cookie': cookie},
    );
    final doc = html_parser.parse(resp.body);
    final opts = doc.querySelectorAll('select[name="course"] option');
    return opts
        .where((o) => (o.attributes['value'] ?? '').isNotEmpty)
        .map((o) => Course(id: o.attributes['value']!, name: o.text.trim()))
        .toList();
  }

  Future<List<Assignment>> getAssignments(String courseId) async {
    final resp = await http.post(
      Uri.parse('$_base/Student/Assignments.php'),
      headers: {
        'Cookie': cookie,
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: {'course': courseId, 'semester': 'Spring-2026'},
    );
    final doc = html_parser.parse(resp.body);
    final rows = doc.querySelectorAll('table tbody tr');
    final List<Assignment> assignments = [];
    for (final row in rows) {
      final cols = row.querySelectorAll('td');
      if (cols.length < 8) continue;
      final deadlineRaw = cols[7].text.trim();
      final deadline = _parseDeadline(deadlineRaw);
      if (deadline == null) continue;
      assignments.add(Assignment(
        number: int.tryParse(cols[0].text.trim()) ?? 0,
        title: cols[1].text.trim(),
        courseId: courseId,
        deadline: deadline,
        submitted: cols[4].text.trim() != 'No Submission',
        marks: cols[5].text.trim(),
      ));
    }
    return assignments;
  }

  Future<bool> uploadAssignment(String courseId, String assignNo, String filePath, String fileName) async {
    final request = http.MultipartRequest('POST', Uri.parse('$_base/Student/Assignments.php'));
    request.headers['Cookie'] = cookie;
    request.fields['course'] = courseId;
    request.fields['assign_no'] = assignNo;
    request.files.add(await http.MultipartFile.fromPath('sub_file', filePath, filename: fileName));
    final resp = await request.send();
    return resp.statusCode == 200;
  }

  DateTime? _parseDeadline(String text) {
    try {
      final lines = text.split('\n').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
      final raw = lines.last;
      final months = {
        'Jan': 1, 'Feb': 2, 'Mar': 3, 'Apr': 4, 'May': 5, 'Jun': 6,
        'Jul': 7, 'Aug': 8, 'Sep': 9, 'Oct': 10, 'Nov': 11, 'Dec': 12
      };
      final regex = RegExp(r'(\d+)\s+(\w+)\s+(\d{4})[- ]+(\d+):(\d+)\s*(am|pm)', caseSensitive: false);
      final match = regex.firstMatch(raw);
      if (match == null) return null;
      int hour = int.parse(match.group(4)!);
      final min = int.parse(match.group(5)!);
      final isPm = match.group(6)!.toLowerCase() == 'pm';
      if (isPm && hour != 12) hour += 12;
      if (!isPm && hour == 12) hour = 0;
      return DateTime(
        int.parse(match.group(3)!),
        months[match.group(2)] ?? 1,
        int.parse(match.group(1)!),
        hour, min,
      );
    } catch (_) {
      return null;
    }
  }
}
