class SmokeEvent {
  final DateTime timestamp;
  final double pricePerStick;

  SmokeEvent({
    required this.timestamp,
    required this.pricePerStick,
  });

  Map<String, dynamic> toJson() => {
        'timestamp': timestamp.toIso8601String(),
        'pricePerStick': pricePerStick,
      };

  factory SmokeEvent.fromJson(Map<String, dynamic> json) {
    return SmokeEvent(
      timestamp: DateTime.parse(json['timestamp']),
      pricePerStick: (json['pricePerStick'] as num? ?? 0.0).toDouble(),
    );
  }
}