class EventTicket {
  final String ticketType;
  final double suggestedPrice;
  final List<String> includedFeatures;
  final List<String> excludedFeatures;
  final String description;
  final bool isSelected;

  EventTicket({
    required this.ticketType,
    required this.suggestedPrice,
    required this.includedFeatures,
    required this.excludedFeatures,
    required this.description,
    this.isSelected = false,
  });

  EventTicket copyWith({
    String? ticketType,
    double? suggestedPrice,
    List<String>? includedFeatures,
    List<String>? excludedFeatures,
    String? description,
    bool? isSelected,
  }) {
    return EventTicket(
      ticketType: ticketType ?? this.ticketType,
      suggestedPrice: suggestedPrice ?? this.suggestedPrice,
      includedFeatures: includedFeatures ?? this.includedFeatures,
      excludedFeatures: excludedFeatures ?? this.excludedFeatures,
      description: description ?? this.description,
      isSelected: isSelected ?? this.isSelected,
    );
  }

  // Helper method to format price
  String get formattedPrice {
    if (suggestedPrice == 0) return 'Gratuit';
    return '€${suggestedPrice.toStringAsFixed(2)}';
  }

  // Helper method to check if it's free
  bool get isFree => suggestedPrice == 0;
}