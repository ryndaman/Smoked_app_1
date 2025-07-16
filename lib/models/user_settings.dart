class UserSettings {
  final int pricePerPack;
  final int cigsPerPack;
  final String preferredCurrency;
  final int baselineCigsPerDay;
  final List<String> smokingTimes;
  final String baseCurrency = 'USD';
  final Map<String, double> exchangeRates = const {
    'USD': 1.0,
    'IDR': 16000.0,
    'EUR': 0.92,
  };

  UserSettings({
    this.pricePerPack = 35000,
    this.cigsPerPack = 16,
    this.preferredCurrency = 'IDR',
    this.baselineCigsPerDay = 20,
    this.smokingTimes = const [],
  });

  double get pricePerStickInBaseCurrency {
    if (cigsPerPack <= 0) return 0.0;
    final priceInPreferredCurrency = pricePerPack / cigsPerPack;
    final rate = exchangeRates[preferredCurrency] ?? 1.0;
    return priceInPreferredCurrency / rate;
  }

  Map<String, dynamic> toJson() => {
        'pricePerPack': pricePerPack,
        'cigsPerPack': cigsPerPack,
        'preferredCurrency': preferredCurrency,
        'baselineCigsPerDay': baselineCigsPerDay,
        'smokingTimes': smokingTimes,
      };

  factory UserSettings.fromJson(Map<String, dynamic> json) {
    var timesFromJson = json['smokingTimes'];
    List<String> smokingTimesList =
        timesFromJson is List ? List<String>.from(timesFromJson) : [];

    return UserSettings(
      pricePerPack: (json['pricePerPack'] as num? ?? 35000).toInt(),
      cigsPerPack: (json['cigsPerPack'] as num? ?? 16).toInt(),
      preferredCurrency: json['preferredCurrency'] as String? ?? 'IDR',
      baselineCigsPerDay: (json['baselineCigsPerDay'] as num? ?? 20).toInt(),
      smokingTimes: smokingTimesList,
    );
  }
}
