class Assignment {
  final int number;
  final String title;
  final String courseId;
  final DateTime deadline;
  final bool submitted;
  final String marks;

  Assignment({
    required this.number,
    required this.title,
    required this.courseId,
    required this.deadline,
    required this.submitted,
    required this.marks,
  });

  bool get isOverdue => deadline.isBefore(DateTime.now());
  bool get isDueSoon => !isOverdue && deadline.difference(DateTime.now()).inHours <= 24;
  bool get isDueVerySoon => !isOverdue && deadline.difference(DateTime.now()).inHours <= 1;

  String get statusLabel {
    if (submitted) return 'Submitted';
    if (isOverdue) return 'Overdue';
    if (isDueVerySoon) return 'Due in < 1hr';
    if (isDueSoon) return 'Due Tomorrow';
    return 'Pending';
  }
}
