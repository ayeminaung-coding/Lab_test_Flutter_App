class ClassSession {
  const ClassSession({
    required this.id,
    required this.studentId,
    required this.checkInTimestamp,
    required this.checkInLatitude,
    required this.checkInLongitude,
    required this.checkInQrCode,
    required this.previousTopic,
    required this.expectedTopic,
    required this.moodBeforeClass,
    this.checkOutTimestamp,
    this.checkOutLatitude,
    this.checkOutLongitude,
    this.checkOutQrCode,
    this.learnedToday,
    this.feedback,
  });

  final int id;
  final String studentId;
  final DateTime checkInTimestamp;
  final double checkInLatitude;
  final double checkInLongitude;
  final String checkInQrCode;
  final String previousTopic;
  final String expectedTopic;
  final int moodBeforeClass;
  final DateTime? checkOutTimestamp;
  final double? checkOutLatitude;
  final double? checkOutLongitude;
  final String? checkOutQrCode;
  final String? learnedToday;
  final String? feedback;

  bool get isCompleted => checkOutTimestamp != null;

  factory ClassSession.fromMap(Map<String, Object?> map) {
    return ClassSession(
      id: map['id'] as int,
      studentId: map['student_id'] as String,
      checkInTimestamp: DateTime.parse(map['check_in_timestamp'] as String),
      checkInLatitude: (map['check_in_latitude'] as num).toDouble(),
      checkInLongitude: (map['check_in_longitude'] as num).toDouble(),
      checkInQrCode: map['check_in_qr_code'] as String,
      previousTopic: map['previous_topic'] as String,
      expectedTopic: map['expected_topic'] as String,
      moodBeforeClass: map['mood_before_class'] as int,
      checkOutTimestamp: map['check_out_timestamp'] != null
          ? DateTime.parse(map['check_out_timestamp'] as String)
          : null,
      checkOutLatitude: (map['check_out_latitude'] as num?)?.toDouble(),
      checkOutLongitude: (map['check_out_longitude'] as num?)?.toDouble(),
      checkOutQrCode: map['check_out_qr_code'] as String?,
      learnedToday: map['learned_today'] as String?,
      feedback: map['feedback'] as String?,
    );
  }
}
