import 'package:intl/intl.dart';

import '../models/finance_models.dart';

class BookingLinks {
  final String googleMapsUrl;
  final String? dbUrl;
  final String? flixBusUrl;
  final String? omioUrl;

  const BookingLinks({
    required this.googleMapsUrl,
    this.dbUrl,
    this.flixBusUrl,
    this.omioUrl,
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
    );
  }

  static String getGoogleMapsLink(String from, String to) {
    return 'https://www.google.com/maps/dir/?api=1'
        '&origin=${Uri.encodeComponent(from)}'
        '&destination=${Uri.encodeComponent(to)}'
        '&travelmode=transit';
  }
}
