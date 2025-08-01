class UserSettings {
  final int pricePerPack;
  final int cigsPerPack;
  final String preferredCurrency;
  final List<String> smokingTimes;
  //user input for baseline
  final int historicalAverage;
  final int? dailyLimit;

  UserSettings({
    this.pricePerPack = 35000,
    this.cigsPerPack = 16,
    this.preferredCurrency = 'IDR',
    this.smokingTimes = const [],
    this.historicalAverage = 16,
    this.dailyLimit,
  });

  // method to create a copy with new values
  UserSettings copyWith({
    int? pricePerPack,
    int? cigsPerPack,
    String? preferredCurrency,
    List<String>? smokingTimes,
    int? historicalAverage,
    int? dailyLimit,
  }) {
    return UserSettings(
      pricePerPack: pricePerPack ?? this.pricePerPack,
      cigsPerPack: cigsPerPack ?? this.cigsPerPack,
      preferredCurrency: preferredCurrency ?? this.preferredCurrency,
      smokingTimes: smokingTimes ?? this.smokingTimes,
      historicalAverage: historicalAverage ?? this.historicalAverage,
      dailyLimit: dailyLimit ?? this.dailyLimit,
    );
  }

  Map<String, dynamic> toJson() => {
        'pricePerPack': pricePerPack,
        'cigsPerPack': cigsPerPack,
        'preferredCurrency': preferredCurrency,
        'smokingTimes': smokingTimes,
        'historicalAverage': historicalAverage,
        'dailyLimit': dailyLimit,
      };

  factory UserSettings.fromJson(Map<String, dynamic> json) {
    var timesFromJson = json['smokingTimes'];
    List<String> smokingTimesList =
        timesFromJson is List ? List<String>.from(timesFromJson) : [];

    return UserSettings(
      pricePerPack: (json['pricePerPack'] as num? ?? 35000).toInt(),
      cigsPerPack: (json['cigsPerPack'] as num? ?? 16).toInt(),
      preferredCurrency: json['preferredCurrency'] as String? ?? 'USD',
      smokingTimes: smokingTimesList,
      historicalAverage: (json['historicalAverage'] as num? ?? 16).toInt(),
      dailyLimit: (json['dailyLimit'] as num?)?.toInt(),
      // dailyLimit: json['dailyLimit'] as int?, << maybe
    );
  }
}
