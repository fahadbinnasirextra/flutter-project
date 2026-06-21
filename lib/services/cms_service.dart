import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html_parser;
import '../models/attendance.dart';

class CmsService {
  static const _base = 'https://cms.bahria.edu.pk';
  final String cookie;
  CmsService(this.cookie);

  Future<List<AttendanceRecord>> getAttendance() async {
    final resp = await http.get(
      Uri.parse('$_base/Sys/Student/Attendance.aspx'),
      headers: {'Cookie': cookie},
    );
    final doc = html_parser.parse(resp.body);
    final rows = doc.querySelectorAll('table tbody tr');
    final List<AttendanceRecord> records = [];
    for (final row in rows) {
      final cols = row.querySelectorAll('td');
      if (cols.length < 4) continue;
      final percentText = cols[3].text.trim().replaceAll('%', '');
      records.add(AttendanceRecord(
        course: cols[0].text.trim(),
        total: int.tryParse(cols[1].text.trim()) ?? 0,
        present: int.tryParse(cols[2].text.trim()) ?? 0,
        percentage: double.tryParse(percentText) ?? 0.0,
      ));
    }
    return records;
  }
}
