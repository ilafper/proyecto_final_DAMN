enum BookingStatus {
  pending,
  confirmed,
  rejected,
  cancelled;

  String get displayName {
    switch (this) {
      case BookingStatus.pending:
        return 'Pendiente';
      case BookingStatus.confirmed:
        return 'Confirmada';
      case BookingStatus.rejected:
        return 'Rechazada';
      case BookingStatus.cancelled:
        return 'Cancelada';
    }
  }
}

class Booking {
  final String id;
  final String venueId;
  final String venueName;
  final String venueCoverUrl;
  final String clientName;
  final String clientPhone;
  final String clientEmail;
  final DateTime date;
  final String timeSlot; // e.g. "17:00 - 21:00"
  final double totalPrice;
  BookingStatus status;
  final String notes;
  String? rejectionReason;
  final DateTime createdAt;

  Booking({
    required this.id,
    required this.venueId,
    required this.venueName,
    required this.venueCoverUrl,
    required this.clientName,
    required this.clientPhone,
    required this.clientEmail,
    required this.date,
    required this.timeSlot,
    required this.totalPrice,
    this.status = BookingStatus.pending,
    required this.notes,
    this.rejectionReason,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();
}
