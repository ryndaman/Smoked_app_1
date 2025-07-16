// lib/models/resisted_event.dart

class ResistedEvent {
  final DateTime timestamp;

  ResistedEvent({required this.timestamp});

  Map<String, dynamic> toJson() => {
        'timestamp': timestamp.toIso8601String(),
      };

  factory ResistedEvent.fromJson(Map<String, dynamic> json) {
    return ResistedEvent(
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
}
