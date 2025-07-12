class EquivalentItem {
  final String name;
  final int price;
  final String iconIdentifier;
  final bool isPromo;
  final String? partnerName;
  final String? promoText;
  final String? promoLink;

  const EquivalentItem({
    required this.name,
    required this.price,
    required this.iconIdentifier,
    this.isPromo = false,
    this.partnerName,
    this.promoText,
    this.promoLink,
  });
}