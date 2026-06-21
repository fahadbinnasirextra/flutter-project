class AttendanceRecord {
  final String course;
  final int total;
  final int present;
  final double percentage;

  AttendanceRecord({
    required this.course,
    required this.total,
    required this.present,
    required this.percentage,
  });

  bool get isCritical => percentage < 75;
  bool get isWarning => percentage >= 75 && percentage < 80;
}
