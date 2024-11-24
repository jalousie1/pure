class SleepRecord {
  final DateTime date;
  final DateTime bedtime;
  final DateTime wakeupTime;

  SleepRecord({
    required this.date,
    required this.bedtime,
    required this.wakeupTime,
  });

  int get durationInMinutes => wakeupTime.difference(bedtime).inMinutes;

  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String(),
        'bedtime': bedtime.toIso8601String(),
        'wakeupTime': wakeupTime.toIso8601String(),
      };

  factory SleepRecord.fromJson(Map<String, dynamic> json) {
    return SleepRecord(
      date: DateTime.parse(json['date'] as String),
      bedtime: DateTime.parse(json['bedtime'] as String),
      wakeupTime: DateTime.parse(json['wakeupTime'] as String),
    );
  }
}
