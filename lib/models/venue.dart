class Venue {
  final String id;
  final String name;
  final String categoryId;
  final String description;
  final String address;
  final String city;
  final int capacityMax;
  final double pricePerHour;
  final List<String> imageUrls;
  final double rating;
  final List<String> amenities;
  final List<String> availableTimeSlots; // e.g. ["10:00 - 14:00", "14:30 - 18:30", "19:00 - 23:00"]

  Venue({
    required this.id,
    required this.name,
    required this.categoryId,
    required this.description,
    required this.address,
    required this.city,
    required this.capacityMax,
    required this.pricePerHour,
    required this.imageUrls,
    this.rating = 4.8,
    required this.amenities,
    List<String>? availableTimeSlots,
  }) : availableTimeSlots = availableTimeSlots ??
            [
              '10:00 - 14:00 (Mañana)',
              '16:00 - 20:00 (Tarde)',
              '20:30 - 00:30 (Noche)',
            ];

  String get coverImage => imageUrls.isNotEmpty
      ? imageUrls.first
      : 'https://images.unsplash.com/photo-1519167758481-83f550bb49b3?auto=format&fit=crop&w=800&q=80';
}
