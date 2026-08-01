import 'package:intl/intl.dart';

import '../models/finance_models.dart';

class BookingLinks {
  final String googleMapsUrl;
  final String? dbUrl;
  final String? flixBusUrl;
  final String? omioUrl;
  final String? sixtUrl;
  final String? hertzUrl;
  final String? europcarUrl;
  final String? skannerUrl;

  const BookingLinks({
    required this.googleMapsUrl,
    this.dbUrl,
    this.flixBusUrl,
    this.omioUrl,
    this.sixtUrl,
    this.hertzUrl,
    this.europcarUrl,
    this.skannerUrl,
  });
}

class BookingService {
  static BookingLinks getLinks({
    required TripTransport transport,
  }) {
    final date = transport.departureDate;
    final from = transport.fromLocation;
    final to = transport.toLocation;
    final dateStr = DateFormat('dd.MM.yyyy').format(date);
    final isoDate = DateFormat('yyyy-MM-dd').format(date);

    return BookingLinks(
      googleMapsUrl: 'https://www.google.com/maps/dir/?api=1'
          '&origin=${Uri.encodeComponent(from)}'
          '&destination=${Uri.encodeComponent(to)}'
          '&travelmode=transit',
      dbUrl: 'https://www.bahn.de/buchung/fahrplan/suche'
          '?stb=true'
          '&so=${Uri.encodeComponent(from)}'
          '&zo=${Uri.encodeComponent(to)}'
          '&date=$dateStr',
      flixBusUrl: 'https://shop.flixbus.com/search'
          '?departureCity=${Uri.encodeComponent(from)}'
          '&arrivalCity=${Uri.encodeComponent(to)}'
          '&rideDate=$isoDate',
      omioUrl: 'https://www.omio.com/search'
          '/${Uri.encodeComponent(from)}/${Uri.encodeComponent(to)}'
          '/$isoDate',
      sixtUrl: 'https://www.sixt.de/car-rental/'
          '?pickupStation=${Uri.encodeComponent(from)}'
          '&returnStation=${Uri.encodeComponent(to)}'
          '&pickupDate=$isoDate',
      hertzUrl: 'https://www.hertz.de/rentacar/reservation/'
          '?pickupLocation=${Uri.encodeComponent(from)}'
          '&returnLocation=${Uri.encodeComponent(to)}'
          '&pickupDate=$isoDate',
      europcarUrl: 'https://www.europcar.de/'
          '?pickupLocation=${Uri.encodeComponent(from)}'
          '&returnLocation=${Uri.encodeComponent(to)}'
          '&pickupDate=$isoDate',
      skannerUrl: 'https://www.skyscanner.de/'
          '?from=${Uri.encodeComponent(from)}'
          '&to=${Uri.encodeComponent(to)}'
          '&depart=$isoDate',
    );
  }

  static BookingLinks getRentalCarLinks({
    required String location,
    required DateTime pickupDate,
    DateTime? returnDate,
  }) {
    final isoPickup = DateFormat('yyyy-MM-dd').format(pickupDate);
    final isoReturn = returnDate != null ? DateFormat('yyyy-MM-dd').format(returnDate) : isoPickup;

    return BookingLinks(
      googleMapsUrl: 'https://www.google.com/maps/search/?api=1'
          '&query=${Uri.encodeComponent(location)}',
      sixtUrl: 'https://www.sixt.de/car-rental/'
          '?pickupStation=${Uri.encodeComponent(location)}'
          '&returnStation=${Uri.encodeComponent(location)}'
          '&pickupDate=$isoPickup'
          '&returnDate=$isoReturn',
      hertzUrl: 'https://www.hertz.de/rentacar/reservation/'
          '?pickupLocation=${Uri.encodeComponent(location)}'
          '&returnLocation=${Uri.encodeComponent(location)}'
          '&pickupDate=$isoPickup'
          '&returnDate=$isoReturn',
      europcarUrl: 'https://www.europcar.de/'
          '?pickupLocation=${Uri.encodeComponent(location)}'
          '&returnLocation=${Uri.encodeComponent(location)}'
          '&pickupDate=$isoPickup'
          '&returnDate=$isoReturn',
    );
  }

  static String getGoogleMapsLink(String from, String to) {
    return 'https://www.google.com/maps/dir/?api=1'
        '&origin=${Uri.encodeComponent(from)}'
        '&destination=${Uri.encodeComponent(to)}'
        '&travelmode=transit';
  }

  static String getGoogleMapsDrivingLink(String from, String to) {
    return 'https://www.google.com/maps/dir/?api=1'
        '&origin=${Uri.encodeComponent(from)}'
        '&destination=${Uri.encodeComponent(to)}'
        '&travelmode=driving';
  }
}
