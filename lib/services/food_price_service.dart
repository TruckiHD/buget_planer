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

  // Länder-Durchschnittswerte (aus Städte-Daten gemittelt + Schätzungen)
  static final Map<String, FoodPriceData> _countryDatabase = {
    // Aus Städte-Daten gemittelt
    'deutschland': const FoodPriceData(city: 'Deutschland', country: 'Deutschland', mealInexpensive: 10.0, mealMidRange: 18.0, groceriesPerDay: 12.0, coffeePrice: 3.2, isCountryLevel: true),
    'germany': const FoodPriceData(city: 'Deutschland', country: 'Deutschland', mealInexpensive: 10.0, mealMidRange: 18.0, groceriesPerDay: 12.0, coffeePrice: 3.2, isCountryLevel: true),
    'frankreich': const FoodPriceData(city: 'Frankreich', country: 'Frankreich', mealInexpensive: 13.0, mealMidRange: 23.0, groceriesPerDay: 14.0, coffeePrice: 3.5, isCountryLevel: true),
    'france': const FoodPriceData(city: 'Frankreich', country: 'Frankreich', mealInexpensive: 13.0, mealMidRange: 23.0, groceriesPerDay: 14.0, coffeePrice: 3.5, isCountryLevel: true),
    'england': const FoodPriceData(city: 'England', country: 'England', mealInexpensive: 15.0, mealMidRange: 26.0, groceriesPerDay: 15.0, coffeePrice: 3.8, isCountryLevel: true),
    'großbritannien': const FoodPriceData(city: 'Großbritannien', country: 'Großbritannien', mealInexpensive: 15.0, mealMidRange: 26.0, groceriesPerDay: 15.0, coffeePrice: 3.8, isCountryLevel: true),
    'great britain': const FoodPriceData(city: 'Großbritannien', country: 'Großbritannien', mealInexpensive: 15.0, mealMidRange: 26.0, groceriesPerDay: 15.0, coffeePrice: 3.8, isCountryLevel: true),
    'uk': const FoodPriceData(city: 'Großbritannien', country: 'Großbritannien', mealInexpensive: 15.0, mealMidRange: 26.0, groceriesPerDay: 15.0, coffeePrice: 3.8, isCountryLevel: true),
    'italien': const FoodPriceData(city: 'Italien', country: 'Italien', mealInexpensive: 11.0, mealMidRange: 20.0, groceriesPerDay: 12.0, coffeePrice: 1.6, isCountryLevel: true),
    'italy': const FoodPriceData(city: 'Italien', country: 'Italien', mealInexpensive: 11.0, mealMidRange: 20.0, groceriesPerDay: 12.0, coffeePrice: 1.6, isCountryLevel: true),
    'spanien': const FoodPriceData(city: 'Spanien', country: 'Spanien', mealInexpensive: 11.0, mealMidRange: 19.0, groceriesPerDay: 10.0, coffeePrice: 1.8, isCountryLevel: true),
    'spain': const FoodPriceData(city: 'Spanien', country: 'Spanien', mealInexpensive: 11.0, mealMidRange: 19.0, groceriesPerDay: 10.0, coffeePrice: 1.8, isCountryLevel: true),
    'niederlande': const FoodPriceData(city: 'Niederlande', country: 'Niederlande', mealInexpensive: 14.0, mealMidRange: 23.0, groceriesPerDay: 13.0, coffeePrice: 3.3, isCountryLevel: true),
    'netherlands': const FoodPriceData(city: 'Niederlande', country: 'Niederlande', mealInexpensive: 14.0, mealMidRange: 23.0, groceriesPerDay: 13.0, coffeePrice: 3.3, isCountryLevel: true),
    'holland': const FoodPriceData(city: 'Niederlande', country: 'Niederlande', mealInexpensive: 14.0, mealMidRange: 23.0, groceriesPerDay: 13.0, coffeePrice: 3.3, isCountryLevel: true),
    'österreich': const FoodPriceData(city: 'Österreich', country: 'Österreich', mealInexpensive: 10.0, mealMidRange: 18.0, groceriesPerDay: 12.0, coffeePrice: 3.8, isCountryLevel: true),
    'austria': const FoodPriceData(city: 'Österreich', country: 'Österreich', mealInexpensive: 10.0, mealMidRange: 18.0, groceriesPerDay: 12.0, coffeePrice: 3.8, isCountryLevel: true),
    'schweiz': const FoodPriceData(city: 'Schweiz', country: 'Schweiz', mealInexpensive: 20.0, mealMidRange: 36.0, groceriesPerDay: 18.0, coffeePrice: 5.0, isCountryLevel: true),
    'switzerland': const FoodPriceData(city: 'Schweiz', country: 'Schweiz', mealInexpensive: 20.0, mealMidRange: 36.0, groceriesPerDay: 18.0, coffeePrice: 5.0, isCountryLevel: true),
    'tschechien': const FoodPriceData(city: 'Tschechien', country: 'Tschechien', mealInexpensive: 6.0, mealMidRange: 13.0, groceriesPerDay: 7.0, coffeePrice: 2.3, isCountryLevel: true),
    'czechia': const FoodPriceData(city: 'Tschechien', country: 'Tschechien', mealInexpensive: 6.0, mealMidRange: 13.0, groceriesPerDay: 7.0, coffeePrice: 2.3, isCountryLevel: true),
    'czech republic': const FoodPriceData(city: 'Tschechien', country: 'Tschechien', mealInexpensive: 6.0, mealMidRange: 13.0, groceriesPerDay: 7.0, coffeePrice: 2.3, isCountryLevel: true),
    'ungarn': const FoodPriceData(city: 'Ungarn', country: 'Ungarn', mealInexpensive: 5.0, mealMidRange: 11.0, groceriesPerDay: 6.0, coffeePrice: 1.8, isCountryLevel: true),
    'hungary': const FoodPriceData(city: 'Ungarn', country: 'Ungarn', mealInexpensive: 5.0, mealMidRange: 11.0, groceriesPerDay: 6.0, coffeePrice: 1.8, isCountryLevel: true),
    'portugal': const FoodPriceData(city: 'Portugal', country: 'Portugal', mealInexpensive: 8.0, mealMidRange: 15.0, groceriesPerDay: 8.0, coffeePrice: 1.3, isCountryLevel: true),
    'irland': const FoodPriceData(city: 'Irland', country: 'Irland', mealInexpensive: 14.0, mealMidRange: 24.0, groceriesPerDay: 13.0, coffeePrice: 3.5, isCountryLevel: true),
    'ireland': const FoodPriceData(city: 'Irland', country: 'Irland', mealInexpensive: 14.0, mealMidRange: 24.0, groceriesPerDay: 13.0, coffeePrice: 3.5, isCountryLevel: true),
    'schweden': const FoodPriceData(city: 'Schweden', country: 'Schweden', mealInexpensive: 12.0, mealMidRange: 21.0, groceriesPerDay: 12.0, coffeePrice: 3.5, isCountryLevel: true),
    'sweden': const FoodPriceData(city: 'Schweden', country: 'Schweden', mealInexpensive: 12.0, mealMidRange: 21.0, groceriesPerDay: 12.0, coffeePrice: 3.5, isCountryLevel: true),
    'norwegen': const FoodPriceData(city: 'Norwegen', country: 'Norwegen', mealInexpensive: 17.0, mealMidRange: 28.0, groceriesPerDay: 16.0, coffeePrice: 4.2, isCountryLevel: true),
    'norway': const FoodPriceData(city: 'Norwegen', country: 'Norwegen', mealInexpensive: 17.0, mealMidRange: 28.0, groceriesPerDay: 16.0, coffeePrice: 4.2, isCountryLevel: true),
    'dänemark': const FoodPriceData(city: 'Dänemark', country: 'Dänemark', mealInexpensive: 14.0, mealMidRange: 26.0, groceriesPerDay: 14.0, coffeePrice: 3.8, isCountryLevel: true),
    'denmark': const FoodPriceData(city: 'Dänemark', country: 'Dänemark', mealInexpensive: 14.0, mealMidRange: 26.0, groceriesPerDay: 14.0, coffeePrice: 3.8, isCountryLevel: true),
    'finnland': const FoodPriceData(city: 'Finnland', country: 'Finnland', mealInexpensive: 11.0, mealMidRange: 19.0, groceriesPerDay: 11.0, coffeePrice: 3.3, isCountryLevel: true),
    'finland': const FoodPriceData(city: 'Finnland', country: 'Finnland', mealInexpensive: 11.0, mealMidRange: 19.0, groceriesPerDay: 11.0, coffeePrice: 3.3, isCountryLevel: true),
    'belgien': const FoodPriceData(city: 'Belgien', country: 'Belgien', mealInexpensive: 12.0, mealMidRange: 21.0, groceriesPerDay: 12.0, coffeePrice: 3.3, isCountryLevel: true),
    'belgium': const FoodPriceData(city: 'Belgien', country: 'Belgien', mealInexpensive: 12.0, mealMidRange: 21.0, groceriesPerDay: 12.0, coffeePrice: 3.3, isCountryLevel: true),
    'griechenland': const FoodPriceData(city: 'Griechenland', country: 'Griechenland', mealInexpensive: 8.0, mealMidRange: 15.0, groceriesPerDay: 8.0, coffeePrice: 2.5, isCountryLevel: true),
    'greece': const FoodPriceData(city: 'Griechenland', country: 'Griechenland', mealInexpensive: 8.0, mealMidRange: 15.0, groceriesPerDay: 8.0, coffeePrice: 2.5, isCountryLevel: true),
    'kroatien': const FoodPriceData(city: 'Kroatien', country: 'Kroatien', mealInexpensive: 7.0, mealMidRange: 14.0, groceriesPerDay: 7.0, coffeePrice: 1.8, isCountryLevel: true),
    'croatia': const FoodPriceData(city: 'Kroatien', country: 'Kroatien', mealInexpensive: 7.0, mealMidRange: 14.0, groceriesPerDay: 7.0, coffeePrice: 1.8, isCountryLevel: true),
    'polen': const FoodPriceData(city: 'Polen', country: 'Polen', mealInexpensive: 6.0, mealMidRange: 12.0, groceriesPerDay: 7.0, coffeePrice: 2.2, isCountryLevel: true),
    'poland': const FoodPriceData(city: 'Polen', country: 'Polen', mealInexpensive: 6.0, mealMidRange: 12.0, groceriesPerDay: 7.0, coffeePrice: 2.2, isCountryLevel: true),
    'türkei': const FoodPriceData(city: 'Türkei', country: 'Türkei', mealInexpensive: 3.5, mealMidRange: 7.0, groceriesPerDay: 4.5, coffeePrice: 1.3, isCountryLevel: true),
    'turkey': const FoodPriceData(city: 'Türkei', country: 'Türkei', mealInexpensive: 3.5, mealMidRange: 7.0, groceriesPerDay: 4.5, coffeePrice: 1.3, isCountryLevel: true),

    // Asien
    'japan': const FoodPriceData(city: 'Japan', country: 'Japan', mealInexpensive: 7.0, mealMidRange: 14.0, groceriesPerDay: 9.0, coffeePrice: 2.8, isCountryLevel: true),
    'thailand': const FoodPriceData(city: 'Thailand', country: 'Thailand', mealInexpensive: 2.5, mealMidRange: 7.0, groceriesPerDay: 4.5, coffeePrice: 1.8, isCountryLevel: true),
    'singapur': const FoodPriceData(city: 'Singapur', country: 'Singapur', mealInexpensive: 7.0, mealMidRange: 16.0, groceriesPerDay: 11.0, coffeePrice: 3.8, isCountryLevel: true),
    'singapore': const FoodPriceData(city: 'Singapur', country: 'Singapur', mealInexpensive: 7.0, mealMidRange: 16.0, groceriesPerDay: 11.0, coffeePrice: 3.8, isCountryLevel: true),
    'china': const FoodPriceData(city: 'China', country: 'China', mealInexpensive: 4.0, mealMidRange: 10.0, groceriesPerDay: 6.0, coffeePrice: 3.5, isCountryLevel: true),
    'südkorea': const FoodPriceData(city: 'Südkorea', country: 'Südkorea', mealInexpensive: 6.0, mealMidRange: 12.0, groceriesPerDay: 9.0, coffeePrice: 3.5, isCountryLevel: true),
    'south korea': const FoodPriceData(city: 'Südkorea', country: 'Südkorea', mealInexpensive: 6.0, mealMidRange: 12.0, groceriesPerDay: 9.0, coffeePrice: 3.5, isCountryLevel: true),
    'indonesien': const FoodPriceData(city: 'Indonesien', country: 'Indonesien', mealInexpensive: 2.0, mealMidRange: 5.0, groceriesPerDay: 3.5, coffeePrice: 1.8, isCountryLevel: true),
    'indonesia': const FoodPriceData(city: 'Indonesien', country: 'Indonesien', mealInexpensive: 2.0, mealMidRange: 5.0, groceriesPerDay: 3.5, coffeePrice: 1.8, isCountryLevel: true),
    'vietnam': const FoodPriceData(city: 'Vietnam', country: 'Vietnam', mealInexpensive: 2.0, mealMidRange: 5.0, groceriesPerDay: 3.5, coffeePrice: 1.5, isCountryLevel: true),
    'indien': const FoodPriceData(city: 'Indien', country: 'Indien', mealInexpensive: 2.0, mealMidRange: 5.0, groceriesPerDay: 3.0, coffeePrice: 1.2, isCountryLevel: true),
    'india': const FoodPriceData(city: 'Indien', country: 'Indien', mealInexpensive: 2.0, mealMidRange: 5.0, groceriesPerDay: 3.0, coffeePrice: 1.2, isCountryLevel: true),
    'vae': const FoodPriceData(city: 'VAE', country: 'VAE', mealInexpensive: 7.0, mealMidRange: 16.0, groceriesPerDay: 11.0, coffeePrice: 4.5, isCountryLevel: true),
    'v.a.e.': const FoodPriceData(city: 'VAE', country: 'VAE', mealInexpensive: 7.0, mealMidRange: 16.0, groceriesPerDay: 11.0, coffeePrice: 4.5, isCountryLevel: true),
    'vereinigte arabische emirate': const FoodPriceData(city: 'VAE', country: 'VAE', mealInexpensive: 7.0, mealMidRange: 16.0, groceriesPerDay: 11.0, coffeePrice: 4.5, isCountryLevel: true),
    'united arab emirates': const FoodPriceData(city: 'VAE', country: 'VAE', mealInexpensive: 7.0, mealMidRange: 16.0, groceriesPerDay: 11.0, coffeePrice: 4.5, isCountryLevel: true),
    'uae': const FoodPriceData(city: 'VAE', country: 'VAE', mealInexpensive: 7.0, mealMidRange: 16.0, groceriesPerDay: 11.0, coffeePrice: 4.5, isCountryLevel: true),

    // Nordamerika
    'usa': const FoodPriceData(city: 'USA', country: 'USA', mealInexpensive: 15.0, mealMidRange: 28.0, groceriesPerDay: 15.0, coffeePrice: 4.3, isCountryLevel: true),
    'kanada': const FoodPriceData(city: 'Kanada', country: 'Kanada', mealInexpensive: 13.0, mealMidRange: 21.0, groceriesPerDay: 12.0, coffeePrice: 3.3, isCountryLevel: true),
    'canada': const FoodPriceData(city: 'Kanada', country: 'Kanada', mealInexpensive: 13.0, mealMidRange: 21.0, groceriesPerDay: 12.0, coffeePrice: 3.3, isCountryLevel: true),
    'mexiko': const FoodPriceData(city: 'Mexiko', country: 'Mexiko', mealInexpensive: 4.5, mealMidRange: 10.0, groceriesPerDay: 5.5, coffeePrice: 2.2, isCountryLevel: true),
    'mexico': const FoodPriceData(city: 'Mexiko', country: 'Mexiko', mealInexpensive: 4.5, mealMidRange: 10.0, groceriesPerDay: 5.5, coffeePrice: 2.2, isCountryLevel: true),

    // Südamerika
    'argentinien': const FoodPriceData(city: 'Argentinien', country: 'Argentinien', mealInexpensive: 4.5, mealMidRange: 11.0, groceriesPerDay: 5.5, coffeePrice: 1.8, isCountryLevel: true),
    'argentina': const FoodPriceData(city: 'Argentinien', country: 'Argentinien', mealInexpensive: 4.5, mealMidRange: 11.0, groceriesPerDay: 5.5, coffeePrice: 1.8, isCountryLevel: true),
    'brasilien': const FoodPriceData(city: 'Brasilien', country: 'Brasilien', mealInexpensive: 4.5, mealMidRange: 11.0, groceriesPerDay: 5.5, coffeePrice: 1.3, isCountryLevel: true),
    'brazil': const FoodPriceData(city: 'Brasilien', country: 'Brasilien', mealInexpensive: 4.5, mealMidRange: 11.0, groceriesPerDay: 5.5, coffeePrice: 1.3, isCountryLevel: true),
    'peru': const FoodPriceData(city: 'Peru', country: 'Peru', mealInexpensive: 3.0, mealMidRange: 9.0, groceriesPerDay: 4.5, coffeePrice: 1.8, isCountryLevel: true),
    'kolumbien': const FoodPriceData(city: 'Kolumbien', country: 'Kolumbien', mealInexpensive: 3.0, mealMidRange: 7.0, groceriesPerDay: 4.0, coffeePrice: 1.0, isCountryLevel: true),
    'colombia': const FoodPriceData(city: 'Kolumbien', country: 'Kolumbien', mealInexpensive: 3.0, mealMidRange: 7.0, groceriesPerDay: 4.0, coffeePrice: 1.0, isCountryLevel: true),
    'chile': const FoodPriceData(city: 'Chile', country: 'Chile', mealInexpensive: 5.5, mealMidRange: 13.0, groceriesPerDay: 6.5, coffeePrice: 2.3, isCountryLevel: true),

    // Ozeanien
    'australien': const FoodPriceData(city: 'Australien', country: 'Australien', mealInexpensive: 13.0, mealMidRange: 22.0, groceriesPerDay: 13.0, coffeePrice: 3.3, isCountryLevel: true),
    'australia': const FoodPriceData(city: 'Australien', country: 'Australien', mealInexpensive: 13.0, mealMidRange: 22.0, groceriesPerDay: 13.0, coffeePrice: 3.3, isCountryLevel: true),
    'neuseeland': const FoodPriceData(city: 'Neuseeland', country: 'Neuseeland', mealInexpensive: 11.0, mealMidRange: 19.0, groceriesPerDay: 11.0, coffeePrice: 3.3, isCountryLevel: true),
    'new zealand': const FoodPriceData(city: 'Neuseeland', country: 'Neuseeland', mealInexpensive: 11.0, mealMidRange: 19.0, groceriesPerDay: 11.0, coffeePrice: 3.3, isCountryLevel: true),

    // Afrika
    'südafrika': const FoodPriceData(city: 'Südafrika', country: 'Südafrika', mealInexpensive: 5.0, mealMidRange: 12.0, groceriesPerDay: 6.0, coffeePrice: 1.8, isCountryLevel: true),
    'south africa': const FoodPriceData(city: 'Südafrika', country: 'Südafrika', mealInexpensive: 5.0, mealMidRange: 12.0, groceriesPerDay: 6.0, coffeePrice: 1.8, isCountryLevel: true),
    'marokko': const FoodPriceData(city: 'Marokko', country: 'Marokko', mealInexpensive: 3.0, mealMidRange: 7.0, groceriesPerDay: 4.0, coffeePrice: 1.3, isCountryLevel: true),
    'morocco': const FoodPriceData(city: 'Marokko', country: 'Marokko', mealInexpensive: 3.0, mealMidRange: 7.0, groceriesPerDay: 4.0, coffeePrice: 1.3, isCountryLevel: true),
    'ägypten': const FoodPriceData(city: 'Ägypten', country: 'Ägypten', mealInexpensive: 2.0, mealMidRange: 5.0, groceriesPerDay: 3.0, coffeePrice: 1.0, isCountryLevel: true),
    'egypt': const FoodPriceData(city: 'Ägypten', country: 'Ägypten', mealInexpensive: 2.0, mealMidRange: 5.0, groceriesPerDay: 3.0, coffeePrice: 1.0, isCountryLevel: true),

    // Zusätzliche Länder (Schätzungen basierend auf Region)
    'litauen': const FoodPriceData(city: 'Litauen', country: 'Litauen', mealInexpensive: 7.0, mealMidRange: 14.0, groceriesPerDay: 7.0, coffeePrice: 2.5, isCountryLevel: true),
    'lithuania': const FoodPriceData(city: 'Litauen', country: 'Litauen', mealInexpensive: 7.0, mealMidRange: 14.0, groceriesPerDay: 7.0, coffeePrice: 2.5, isCountryLevel: true),
    'lettland': const FoodPriceData(city: 'Lettland', country: 'Lettland', mealInexpensive: 7.0, mealMidRange: 14.0, groceriesPerDay: 7.0, coffeePrice: 2.5, isCountryLevel: true),
    'latvia': const FoodPriceData(city: 'Lettland', country: 'Lettland', mealInexpensive: 7.0, mealMidRange: 14.0, groceriesPerDay: 7.0, coffeePrice: 2.5, isCountryLevel: true),
    'estland': const FoodPriceData(city: 'Estland', country: 'Estland', mealInexpensive: 8.0, mealMidRange: 15.0, groceriesPerDay: 8.0, coffeePrice: 2.8, isCountryLevel: true),
    'estonia': const FoodPriceData(city: 'Estland', country: 'Estland', mealInexpensive: 8.0, mealMidRange: 15.0, groceriesPerDay: 8.0, coffeePrice: 2.8, isCountryLevel: true),
    'rumänien': const FoodPriceData(city: 'Rumänien', country: 'Rumänien', mealInexpensive: 5.0, mealMidRange: 10.0, groceriesPerDay: 5.0, coffeePrice: 2.0, isCountryLevel: true),
    'romania': const FoodPriceData(city: 'Rumänien', country: 'Rumänien', mealInexpensive: 5.0, mealMidRange: 10.0, groceriesPerDay: 5.0, coffeePrice: 2.0, isCountryLevel: true),
    'bulgarien': const FoodPriceData(city: 'Bulgarien', country: 'Bulgarien', mealInexpensive: 4.0, mealMidRange: 9.0, groceriesPerDay: 4.5, coffeePrice: 1.5, isCountryLevel: true),
    'bulgaria': const FoodPriceData(city: 'Bulgarien', country: 'Bulgarien', mealInexpensive: 4.0, mealMidRange: 9.0, groceriesPerDay: 4.5, coffeePrice: 1.5, isCountryLevel: true),
    'serbien': const FoodPriceData(city: 'Serbien', country: 'Serbien', mealInexpensive: 4.0, mealMidRange: 9.0, groceriesPerDay: 4.5, coffeePrice: 1.5, isCountryLevel: true),
    'serbia': const FoodPriceData(city: 'Serbien', country: 'Serbien', mealInexpensive: 4.0, mealMidRange: 9.0, groceriesPerDay: 4.5, coffeePrice: 1.5, isCountryLevel: true),
    'slowenien': const FoodPriceData(city: 'Slowenien', country: 'Slowenien', mealInexpensive: 7.0, mealMidRange: 14.0, groceriesPerDay: 7.0, coffeePrice: 2.0, isCountryLevel: true),
    'slovenia': const FoodPriceData(city: 'Slowenien', country: 'Slowenien', mealInexpensive: 7.0, mealMidRange: 14.0, groceriesPerDay: 7.0, coffeePrice: 2.0, isCountryLevel: true),
    'slowakei': const FoodPriceData(city: 'Slowakei', country: 'Slowakei', mealInexpensive: 5.0, mealMidRange: 11.0, groceriesPerDay: 6.0, coffeePrice: 2.0, isCountryLevel: true),
    'slovakia': const FoodPriceData(city: 'Slowakei', country: 'Slowakei', mealInexpensive: 5.0, mealMidRange: 11.0, groceriesPerDay: 6.0, coffeePrice: 2.0, isCountryLevel: true),
    'georgien': const FoodPriceData(city: 'Georgien', country: 'Georgien', mealInexpensive: 4.0, mealMidRange: 9.0, groceriesPerDay: 4.5, coffeePrice: 1.5, isCountryLevel: true),
    'georgia': const FoodPriceData(city: 'Georgien', country: 'Georgien', mealInexpensive: 4.0, mealMidRange: 9.0, groceriesPerDay: 4.5, coffeePrice: 1.5, isCountryLevel: true),
    'armenien': const FoodPriceData(city: 'Armenien', country: 'Armenien', mealInexpensive: 3.5, mealMidRange: 8.0, groceriesPerDay: 4.0, coffeePrice: 1.3, isCountryLevel: true),
    'armenia': const FoodPriceData(city: 'Armenien', country: 'Armenien', mealInexpensive: 3.5, mealMidRange: 8.0, groceriesPerDay: 4.0, coffeePrice: 1.3, isCountryLevel: true),
    'philippinen': const FoodPriceData(city: 'Philippinen', country: 'Philippinen', mealInexpensive: 2.5, mealMidRange: 6.0, groceriesPerDay: 4.0, coffeePrice: 2.0, isCountryLevel: true),
    'philippines': const FoodPriceData(city: 'Philippinen', country: 'Philippinen', mealInexpensive: 2.5, mealMidRange: 6.0, groceriesPerDay: 4.0, coffeePrice: 2.0, isCountryLevel: true),
    'malaysia': const FoodPriceData(city: 'Malaysia', country: 'Malaysia', mealInexpensive: 3.0, mealMidRange: 7.0, groceriesPerDay: 4.5, coffeePrice: 2.5, isCountryLevel: true),
    'taiwan': const FoodPriceData(city: 'Taiwan', country: 'Taiwan', mealInexpensive: 4.0, mealMidRange: 10.0, groceriesPerDay: 6.0, coffeePrice: 3.0, isCountryLevel: true),
    'sri lanka': const FoodPriceData(city: 'Sri Lanka', country: 'Sri Lanka', mealInexpensive: 2.0, mealMidRange: 5.0, groceriesPerDay: 3.0, coffeePrice: 1.5, isCountryLevel: true),
    'nepal': const FoodPriceData(city: 'Nepal', country: 'Nepal', mealInexpensive: 2.0, mealMidRange: 4.5, groceriesPerDay: 3.0, coffeePrice: 1.2, isCountryLevel: true),
    'kambodscha': const FoodPriceData(city: 'Kambodscha', country: 'Kambodscha', mealInexpensive: 2.0, mealMidRange: 5.0, groceriesPerDay: 3.5, coffeePrice: 1.5, isCountryLevel: true),
    'cambodia': const FoodPriceData(city: 'Kambodscha', country: 'Kambodscha', mealInexpensive: 2.0, mealMidRange: 5.0, groceriesPerDay: 3.5, coffeePrice: 1.5, isCountryLevel: true),
    'myanmar': const FoodPriceData(city: 'Myanmar', country: 'Myanmar', mealInexpensive: 2.0, mealMidRange: 5.0, groceriesPerDay: 3.0, coffeePrice: 1.5, isCountryLevel: true),
    'laos': const FoodPriceData(city: 'Laos', country: 'Laos', mealInexpensive: 2.0, mealMidRange: 5.0, groceriesPerDay: 3.5, coffeePrice: 1.5, isCountryLevel: true),
    'tunesien': const FoodPriceData(city: 'Tunesien', country: 'Tunesien', mealInexpensive: 2.5, mealMidRange: 6.0, groceriesPerDay: 3.5, coffeePrice: 1.0, isCountryLevel: true),
    'tunisia': const FoodPriceData(city: 'Tunesien', country: 'Tunesien', mealInexpensive: 2.5, mealMidRange: 6.0, groceriesPerDay: 3.5, coffeePrice: 1.0, isCountryLevel: true),
    'kenia': const FoodPriceData(city: 'Kenia', country: 'Kenia', mealInexpensive: 2.5, mealMidRange: 6.0, groceriesPerDay: 3.5, coffeePrice: 1.5, isCountryLevel: true),
    'kenya': const FoodPriceData(city: 'Kenia', country: 'Kenia', mealInexpensive: 2.5, mealMidRange: 6.0, groceriesPerDay: 3.5, coffeePrice: 1.5, isCountryLevel: true),
    'tansania': const FoodPriceData(city: 'Tansania', country: 'Tansania', mealInexpensive: 2.0, mealMidRange: 5.0, groceriesPerDay: 3.0, coffeePrice: 1.2, isCountryLevel: true),
    'tanzania': const FoodPriceData(city: 'Tansania', country: 'Tansania', mealInexpensive: 2.0, mealMidRange: 5.0, groceriesPerDay: 3.0, coffeePrice: 1.2, isCountryLevel: true),
    'kuba': const FoodPriceData(city: 'Kuba', country: 'Kuba', mealInexpensive: 4.0, mealMidRange: 9.0, groceriesPerDay: 5.0, coffeePrice: 1.5, isCountryLevel: true),
    'cuba': const FoodPriceData(city: 'Kuba', country: 'Kuba', mealInexpensive: 4.0, mealMidRange: 9.0, groceriesPerDay: 5.0, coffeePrice: 1.5, isCountryLevel: true),
    'dominikanische republik': const FoodPriceData(city: 'Dominikanische Republik', country: 'Dominikanische Republik', mealInexpensive: 4.0, mealMidRange: 9.0, groceriesPerDay: 5.0, coffeePrice: 1.5, isCountryLevel: true),
    'dominican republic': const FoodPriceData(city: 'Dominikanische Republik', country: 'Dominikanische Republik', mealInexpensive: 4.0, mealMidRange: 9.0, groceriesPerDay: 5.0, coffeePrice: 1.5, isCountryLevel: true),
    'island': const FoodPriceData(city: 'Island', country: 'Island', mealInexpensive: 16.0, mealMidRange: 28.0, groceriesPerDay: 15.0, coffeePrice: 4.0, isCountryLevel: true),
    'iceland': const FoodPriceData(city: 'Island', country: 'Island', mealInexpensive: 16.0, mealMidRange: 28.0, groceriesPerDay: 15.0, coffeePrice: 4.0, isCountryLevel: true),
    'luxemburg': const FoodPriceData(city: 'Luxemburg', country: 'Luxemburg', mealInexpensive: 14.0, mealMidRange: 24.0, groceriesPerDay: 13.0, coffeePrice: 3.5, isCountryLevel: true),
    'luxembourg': const FoodPriceData(city: 'Luxemburg', country: 'Luxemburg', mealInexpensive: 14.0, mealMidRange: 24.0, groceriesPerDay: 13.0, coffeePrice: 3.5, isCountryLevel: true),
    'malta': const FoodPriceData(city: 'Malta', country: 'Malta', mealInexpensive: 10.0, mealMidRange: 18.0, groceriesPerDay: 10.0, coffeePrice: 2.5, isCountryLevel: true),
    'zypern': const FoodPriceData(city: 'Zypern', country: 'Zypern', mealInexpensive: 9.0, mealMidRange: 16.0, groceriesPerDay: 9.0, coffeePrice: 2.8, isCountryLevel: true),
    'cyprus': const FoodPriceData(city: 'Zypern', country: 'Zypern', mealInexpensive: 9.0, mealMidRange: 16.0, groceriesPerDay: 9.0, coffeePrice: 2.8, isCountryLevel: true),
  };

  static FoodPriceData? lookup(String city) {
    final normalized = city.toLowerCase().trim();
    if (normalized.isEmpty) return null;

    // 1. Exakter Stadt-Match
    if (_database.containsKey(normalized)) return _database[normalized];

    // 2. Substring-Match in Städte-DB
    for (final entry in _database.entries) {
      if (normalized.contains(entry.key) || entry.key.contains(normalized)) {
        return entry.value;
      }
    }

    // 3. Land aus Location-String extrahieren (z.B. "Heidelberg, Deutschland")
    final countryFromLocation = _extractCountry(normalized);
    if (countryFromLocation != null) return countryFromLocation;

    // 4. Substring-Match in Länder-DB gegen den gesamten Location-String
    for (final entry in _countryDatabase.entries) {
      if (normalized.contains(entry.key)) {
        return entry.value;
      }
    }

    return null;
  }

  static FoodPriceData? _extractCountry(String normalized) {
    // Versuche "stadt, land" oder "stadt land" zu splitten
    final parts = normalized.split(RegExp(r'[,;|]'));
    final lastPart = parts.last.trim();
    if (lastPart.isNotEmpty && _countryDatabase.containsKey(lastPart)) {
      return _countryDatabase[lastPart];
    }

    // Auch ohne Trennzeichen: prüfe ob letztes Wort ein Land ist
    final words = normalized.split(RegExp(r'\s+'));
    for (int len = 3; len >= 1; len--) {
      if (words.length >= len) {
        final candidate = words.sublist(words.length - len).join(' ');
        if (_countryDatabase.containsKey(candidate)) {
          return _countryDatabase[candidate];
        }
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

  static List<String> get availableCountries => _countryDatabase.values
      .map((d) => d.country)
      .toSet()
      .toList()
    ..sort();
}
