import '../models/finance_models.dart';

class FoodPriceService {
  static final Map<String, FoodPriceData> _database = {
    // Deutschland
    'berlin': const FoodPriceData(city: 'Berlin', country: 'Deutschland', mealInexpensive: 10.0, mealMidRange: 18.0, groceriesPerDay: 12.0, coffeePrice: 3.2),
    'münchen': const FoodPriceData(city: 'München', country: 'Deutschland', mealInexpensive: 12.0, mealMidRange: 20.0, groceriesPerDay: 14.0, coffeePrice: 3.5),
    'muenchen': const FoodPriceData(city: 'München', country: 'Deutschland', mealInexpensive: 12.0, mealMidRange: 20.0, groceriesPerDay: 14.0, coffeePrice: 3.5),
    'hamburg': const FoodPriceData(city: 'Hamburg', country: 'Deutschland', mealInexpensive: 10.0, mealMidRange: 18.0, groceriesPerDay: 12.0, coffeePrice: 3.2),
    'köln': const FoodPriceData(city: 'Köln', country: 'Deutschland', mealInexpensive: 10.0, mealMidRange: 17.0, groceriesPerDay: 12.0, coffeePrice: 3.0),
    'frankfurt': const FoodPriceData(city: 'Frankfurt', country: 'Deutschland', mealInexpensive: 11.0, mealMidRange: 19.0, groceriesPerDay: 13.0, coffeePrice: 3.3),
    'dresden': const FoodPriceData(city: 'Dresden', country: 'Deutschland', mealInexpensive: 8.0, mealMidRange: 15.0, groceriesPerDay: 10.0, coffeePrice: 2.8),

    // Europa
    'paris': const FoodPriceData(city: 'Paris', country: 'Frankreich', mealInexpensive: 14.0, mealMidRange: 25.0, groceriesPerDay: 15.0, coffeePrice: 3.8),
    'london': const FoodPriceData(city: 'London', country: 'England', mealInexpensive: 16.0, mealMidRange: 28.0, groceriesPerDay: 16.0, coffeePrice: 4.0),
    'rom': const FoodPriceData(city: 'Rom', country: 'Italien', mealInexpensive: 12.0, mealMidRange: 22.0, groceriesPerDay: 13.0, coffeePrice: 1.8),
    'roma': const FoodPriceData(city: 'Rom', country: 'Italien', mealInexpensive: 12.0, mealMidRange: 22.0, groceriesPerDay: 13.0, coffeePrice: 1.8),
    'barcelona': const FoodPriceData(city: 'Barcelona', country: 'Spanien', mealInexpensive: 12.0, mealMidRange: 20.0, groceriesPerDay: 11.0, coffeePrice: 2.0),
    'madrid': const FoodPriceData(city: 'Madrid', country: 'Spanien', mealInexpensive: 11.0, mealMidRange: 18.0, groceriesPerDay: 10.0, coffeePrice: 1.8),
    'amsterdam': const FoodPriceData(city: 'Amsterdam', country: 'Niederlande', mealInexpensive: 15.0, mealMidRange: 25.0, groceriesPerDay: 14.0, coffeePrice: 3.5),
    'wien': const FoodPriceData(city: 'Wien', country: 'Österreich', mealInexpensive: 10.0, mealMidRange: 18.0, groceriesPerDay: 12.0, coffeePrice: 3.8),
    'vienna': const FoodPriceData(city: 'Wien', country: 'Österreich', mealInexpensive: 10.0, mealMidRange: 18.0, groceriesPerDay: 12.0, coffeePrice: 3.8),
    'zürich': const FoodPriceData(city: 'Zürich', country: 'Schweiz', mealInexpensive: 22.0, mealMidRange: 40.0, groceriesPerDay: 20.0, coffeePrice: 5.5),
    'zurich': const FoodPriceData(city: 'Zürich', country: 'Schweiz', mealInexpensive: 22.0, mealMidRange: 40.0, groceriesPerDay: 20.0, coffeePrice: 5.5),
    'prag': const FoodPriceData(city: 'Prag', country: 'Tschechien', mealInexpensive: 7.0, mealMidRange: 14.0, groceriesPerDay: 8.0, coffeePrice: 2.5),
    'prague': const FoodPriceData(city: 'Prag', country: 'Tschechien', mealInexpensive: 7.0, mealMidRange: 14.0, groceriesPerDay: 8.0, coffeePrice: 2.5),
    'budapest': const FoodPriceData(city: 'Budapest', country: 'Ungarn', mealInexpensive: 6.0, mealMidRange: 12.0, groceriesPerDay: 7.0, coffeePrice: 2.0),
    'lisbon': const FoodPriceData(city: 'Lissabon', country: 'Portugal', mealInexpensive: 9.0, mealMidRange: 16.0, groceriesPerDay: 9.0, coffeePrice: 1.5),
    'lissabon': const FoodPriceData(city: 'Lissabon', country: 'Portugal', mealInexpensive: 9.0, mealMidRange: 16.0, groceriesPerDay: 9.0, coffeePrice: 1.5),
    'dublin': const FoodPriceData(city: 'Dublin', country: 'Irland', mealInexpensive: 15.0, mealMidRange: 25.0, groceriesPerDay: 14.0, coffeePrice: 3.8),
    'stockholm': const FoodPriceData(city: 'Stockholm', country: 'Schweden', mealInexpensive: 13.0, mealMidRange: 22.0, groceriesPerDay: 13.0, coffeePrice: 3.8),
    'oslo': const FoodPriceData(city: 'Oslo', country: 'Norwegen', mealInexpensive: 18.0, mealMidRange: 30.0, groceriesPerDay: 18.0, coffeePrice: 4.5),
    'kopenhagen': const FoodPriceData(city: 'Kopenhagen', country: 'Dänemark', mealInexpensive: 15.0, mealMidRange: 28.0, groceriesPerDay: 15.0, coffeePrice: 4.0),
    'copenhagen': const FoodPriceData(city: 'Kopenhagen', country: 'Dänemark', mealInexpensive: 15.0, mealMidRange: 28.0, groceriesPerDay: 15.0, coffeePrice: 4.0),
    'helsinki': const FoodPriceData(city: 'Helsinki', country: 'Finnland', mealInexpensive: 12.0, mealMidRange: 20.0, groceriesPerDay: 12.0, coffeePrice: 3.5),
    'brüssel': const FoodPriceData(city: 'Brüssel', country: 'Belgien', mealInexpensive: 13.0, mealMidRange: 22.0, groceriesPerDay: 13.0, coffeePrice: 3.5),
    'athen': const FoodPriceData(city: 'Athen', country: 'Griechenland', mealInexpensive: 9.0, mealMidRange: 16.0, groceriesPerDay: 9.0, coffeePrice: 2.8),
    'athens': const FoodPriceData(city: 'Athen', country: 'Griechenland', mealInexpensive: 9.0, mealMidRange: 16.0, groceriesPerDay: 9.0, coffeePrice: 2.8),
    'split': const FoodPriceData(city: 'Split', country: 'Kroatien', mealInexpensive: 8.0, mealMidRange: 15.0, groceriesPerDay: 8.0, coffeePrice: 2.0),
    'krakau': const FoodPriceData(city: 'Krakau', country: 'Polen', mealInexpensive: 6.0, mealMidRange: 12.0, groceriesPerDay: 7.0, coffeePrice: 2.2),
    'krakow': const FoodPriceData(city: 'Krakau', country: 'Polen', mealInexpensive: 6.0, mealMidRange: 12.0, groceriesPerDay: 7.0, coffeePrice: 2.2),
    'warschau': const FoodPriceData(city: 'Warschau', country: 'Polen', mealInexpensive: 6.0, mealMidRange: 13.0, groceriesPerDay: 7.0, coffeePrice: 2.3),
    'istanbul': const FoodPriceData(city: 'Istanbul', country: 'Türkei', mealInexpensive: 4.0, mealMidRange: 8.0, groceriesPerDay: 5.0, coffeePrice: 1.5),

    // Asien
    'tokyo': const FoodPriceData(city: 'Tokyo', country: 'Japan', mealInexpensive: 7.5, mealMidRange: 15.0, groceriesPerDay: 10.0, coffeePrice: 3.0),
    'kyoto': const FoodPriceData(city: 'Kyoto', country: 'Japan', mealInexpensive: 7.0, mealMidRange: 14.0, groceriesPerDay: 9.0, coffeePrice: 3.0),
    'osaka': const FoodPriceData(city: 'Osaka', country: 'Japan', mealInexpensive: 7.0, mealMidRange: 14.0, groceriesPerDay: 9.0, coffeePrice: 2.8),
    'bangkok': const FoodPriceData(city: 'Bangkok', country: 'Thailand', mealInexpensive: 2.5, mealMidRange: 8.0, groceriesPerDay: 5.0, coffeePrice: 2.0),
    'singapore': const FoodPriceData(city: 'Singapur', country: 'Singapur', mealInexpensive: 8.0, mealMidRange: 18.0, groceriesPerDay: 12.0, coffeePrice: 4.0),
    'hongkong': const FoodPriceData(city: 'Hongkong', country: 'China', mealInexpensive: 6.0, mealMidRange: 14.0, groceriesPerDay: 10.0, coffeePrice: 4.0),
    'seoul': const FoodPriceData(city: 'Seoul', country: 'Südkorea', mealInexpensive: 6.0, mealMidRange: 12.0, groceriesPerDay: 9.0, coffeePrice: 3.5),
    'peking': const FoodPriceData(city: 'Peking', country: 'China', mealInexpensive: 4.0, mealMidRange: 10.0, groceriesPerDay: 6.0, coffeePrice: 3.5),
    'beijing': const FoodPriceData(city: 'Peking', country: 'China', mealInexpensive: 4.0, mealMidRange: 10.0, groceriesPerDay: 6.0, coffeePrice: 3.5),
    'shanghai': const FoodPriceData(city: 'Shanghai', country: 'China', mealInexpensive: 4.5, mealMidRange: 12.0, groceriesPerDay: 7.0, coffeePrice: 3.8),
    'bali': const FoodPriceData(city: 'Bali', country: 'Indonesien', mealInexpensive: 2.0, mealMidRange: 6.0, groceriesPerDay: 4.0, coffeePrice: 2.0),
    'hanoi': const FoodPriceData(city: 'Hanoi', country: 'Vietnam', mealInexpensive: 2.0, mealMidRange: 5.0, groceriesPerDay: 3.5, coffeePrice: 1.5),
    'ho chi minh': const FoodPriceData(city: 'Ho Chi Minh', country: 'Vietnam', mealInexpensive: 2.0, mealMidRange: 6.0, groceriesPerDay: 4.0, coffeePrice: 1.5),
    'mumbai': const FoodPriceData(city: 'Mumbai', country: 'Indien', mealInexpensive: 2.5, mealMidRange: 6.0, groceriesPerDay: 3.5, coffeePrice: 1.5),
    'delhi': const FoodPriceData(city: 'Delhi', country: 'Indien', mealInexpensive: 2.0, mealMidRange: 5.0, groceriesPerDay: 3.0, coffeePrice: 1.2),
    'dubai': const FoodPriceData(city: 'Dubai', country: 'VAE', mealInexpensive: 8.0, mealMidRange: 18.0, groceriesPerDay: 12.0, coffeePrice: 5.0),

    // Nordamerika
    'new york': const FoodPriceData(city: 'New York', country: 'USA', mealInexpensive: 18.0, mealMidRange: 35.0, groceriesPerDay: 18.0, coffeePrice: 4.5),
    'los angeles': const FoodPriceData(city: 'Los Angeles', country: 'USA', mealInexpensive: 15.0, mealMidRange: 28.0, groceriesPerDay: 15.0, coffeePrice: 4.5),
    'san francisco': const FoodPriceData(city: 'San Francisco', country: 'USA', mealInexpensive: 16.0, mealMidRange: 30.0, groceriesPerDay: 16.0, coffeePrice: 4.8),
    'chicago': const FoodPriceData(city: 'Chicago', country: 'USA', mealInexpensive: 14.0, mealMidRange: 25.0, groceriesPerDay: 14.0, coffeePrice: 4.2),
    'toronto': const FoodPriceData(city: 'Toronto', country: 'Kanada', mealInexpensive: 14.0, mealMidRange: 22.0, groceriesPerDay: 13.0, coffeePrice: 3.5),
    'vancouver': const FoodPriceData(city: 'Vancouver', country: 'Kanada', mealInexpensive: 13.0, mealMidRange: 22.0, groceriesPerDay: 13.0, coffeePrice: 3.5),
    'mexiko-stadt': const FoodPriceData(city: 'Mexiko-Stadt', country: 'Mexiko', mealInexpensive: 5.0, mealMidRange: 12.0, groceriesPerDay: 6.0, coffeePrice: 2.5),

    // Südamerika
    'buenos aires': const FoodPriceData(city: 'Buenos Aires', country: 'Argentinien', mealInexpensive: 5.0, mealMidRange: 12.0, groceriesPerDay: 6.0, coffeePrice: 2.0),
    'rio de janeiro': const FoodPriceData(city: 'Rio de Janeiro', country: 'Brasilien', mealInexpensive: 5.0, mealMidRange: 12.0, groceriesPerDay: 6.0, coffeePrice: 1.5),
    'lima': const FoodPriceData(city: 'Lima', country: 'Peru', mealInexpensive: 3.5, mealMidRange: 10.0, groceriesPerDay: 5.0, coffeePrice: 2.0),
    'bogota': const FoodPriceData(city: 'Bogotá', country: 'Kolumbien', mealInexpensive: 3.0, mealMidRange: 8.0, groceriesPerDay: 4.5, coffeePrice: 1.2),
    'santiago': const FoodPriceData(city: 'Santiago', country: 'Chile', mealInexpensive: 6.0, mealMidRange: 14.0, groceriesPerDay: 7.0, coffeePrice: 2.5),

    // Ozeanien
    'sydney': const FoodPriceData(city: 'Sydney', country: 'Australien', mealInexpensive: 14.0, mealMidRange: 24.0, groceriesPerDay: 14.0, coffeePrice: 3.5),
    'melbourne': const FoodPriceData(city: 'Melbourne', country: 'Australien', mealInexpensive: 13.0, mealMidRange: 22.0, groceriesPerDay: 13.0, coffeePrice: 3.5),
    'auckland': const FoodPriceData(city: 'Auckland', country: 'Neuseeland', mealInexpensive: 12.0, mealMidRange: 20.0, groceriesPerDay: 12.0, coffeePrice: 3.5),

    // Afrika
    'kapstadt': const FoodPriceData(city: 'Kapstadt', country: 'Südafrika', mealInexpensive: 6.0, mealMidRange: 14.0, groceriesPerDay: 7.0, coffeePrice: 2.0),
    'marrakesch': const FoodPriceData(city: 'Marrakesch', country: 'Marokko', mealInexpensive: 3.0, mealMidRange: 8.0, groceriesPerDay: 4.0, coffeePrice: 1.5),
    'kairo': const FoodPriceData(city: 'Kairo', country: 'Ägypten', mealInexpensive: 2.5, mealMidRange: 6.0, groceriesPerDay: 3.5, coffeePrice: 1.2),
  };

  static FoodPriceData? lookup(String city) {
    final normalized = city.toLowerCase().trim();
    if (_database.containsKey(normalized)) return _database[normalized];
    for (final entry in _database.entries) {
      if (normalized.contains(entry.key) || entry.key.contains(normalized)) {
        return entry.value;
      }
    }
    return null;
  }

  static int suggestDailyBudgetCents(String city, {bool budget = false, bool comfortable = false}) {
    final data = lookup(city);
    if (data == null) return 3000;
    if (budget) return data.budgetCents;
    if (comfortable) return data.comfortableCents;
    return data.suggestedBudgetCents;
  }

  static List<String> get availableCities => _database.values
      .map((d) => '${d.city}, ${d.country}')
      .toSet()
      .toList()
    ..sort();
}
