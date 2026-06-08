import 'dart:convert';

import 'package:http/http.dart' as http;

class WeatherLookupException implements Exception {
  final String message;

  const WeatherLookupException(this.message);

  @override
  String toString() => message;
}

class WeatherService {
  static const _clientHeader = {'User-Agent': 'my_garage_weather/1.0'};
  static const Duration _requestTimeout = Duration(seconds: 8);

  Future<WeatherSnapshot> fetchForecast(
    String city, {
    required String language,
  }) async {
    final location = await _resolveLocation(city, language: language);
    final uri = Uri.https('api.open-meteo.com', '/v1/forecast', {
      'latitude': location.latitude.toString(),
      'longitude': location.longitude.toString(),
      'current': 'temperature_2m,weather_code,wind_speed_10m',
      'hourly': 'temperature_2m,precipitation_probability,weather_code',
      'forecast_days': '1',
      'timezone': 'auto',
    });

    final response = await _getWithRetry(
      uri,
      errorKey: 'weather_request_failed',
    );

    final Map<String, dynamic> data =
        jsonDecode(response.body) as Map<String, dynamic>;
    final current = data['current'] as Map<String, dynamic>?;
    final hourly = data['hourly'] as Map<String, dynamic>?;
    if (current == null || hourly == null) {
      throw const WeatherLookupException('weather_invalid_response');
    }

    final currentTime = current['time'] as String?;
    final times = (hourly['time'] as List<dynamic>? ?? const [])
        .whereType<String>()
        .toList();
    final temperatures =
        (hourly['temperature_2m'] as List<dynamic>? ?? const [])
            .map((value) => (value as num?)?.toDouble())
            .toList();
    final rainChances =
        (hourly['precipitation_probability'] as List<dynamic>? ?? const [])
            .map((value) => (value as num?)?.toInt())
            .toList();
    final weatherCodes = (hourly['weather_code'] as List<dynamic>? ?? const [])
        .map((value) => (value as num?)?.toInt())
        .toList();

    int startIndex = 0;
    if (currentTime != null) {
      final matchedIndex = times.indexOf(currentTime);
      if (matchedIndex >= 0) {
        startIndex = matchedIndex;
      }
    }

    final hourlyForecast = <HourlyForecast>[];
    for (
      int index = startIndex;
      index < times.length && hourlyForecast.length < 6;
      index++
    ) {
      final temperature = index < temperatures.length
          ? temperatures[index]
          : null;
      final rainChance = index < rainChances.length ? rainChances[index] : null;
      final weatherCode = index < weatherCodes.length
          ? weatherCodes[index]
          : null;
      if (temperature == null || rainChance == null || weatherCode == null) {
        continue;
      }
      hourlyForecast.add(
        HourlyForecast(
          time: DateTime.tryParse(times[index]) ?? DateTime.now(),
          temperatureC: temperature,
          rainChance: rainChance,
          weatherCode: weatherCode,
        ),
      );
    }

    return WeatherSnapshot(
      cityName: location.label,
      temperatureC: (current['temperature_2m'] as num?)?.toDouble() ?? 0,
      windSpeedKmh: (current['wind_speed_10m'] as num?)?.toDouble() ?? 0,
      weatherCode: (current['weather_code'] as num?)?.toInt() ?? 0,
      updatedAt: DateTime.tryParse(currentTime ?? '') ?? DateTime.now(),
      hourly: hourlyForecast,
    );
  }

  Future<_ResolvedLocation> _resolveLocation(
    String city, {
    required String language,
  }) async {
    final localLocation = _resolveLocalLocation(city, language: language);
    if (localLocation != null) {
      return localLocation;
    }

    final uri = Uri.https('geocoding-api.open-meteo.com', '/v1/search', {
      'name': city,
      'count': '1',
      'language': language,
      'format': 'json',
    });

    final response = await _getWithRetry(
      uri,
      errorKey: 'geocoding_request_failed',
    );

    final Map<String, dynamic> data =
        jsonDecode(response.body) as Map<String, dynamic>;
    final results = data['results'] as List<dynamic>?;
    if (results == null || results.isEmpty) {
      throw const WeatherLookupException('location_not_found');
    }

    final result = results.first as Map<String, dynamic>;
    final latitude = (result['latitude'] as num?)?.toDouble();
    final longitude = (result['longitude'] as num?)?.toDouble();
    final name = result['name'] as String?;
    if (latitude == null || longitude == null || name == null || name.isEmpty) {
      throw const WeatherLookupException('location_not_found');
    }

    final admin = result['admin1'] as String?;
    final country = result['country_code'] as String?;
    final parts = [
      name,
      if (admin != null && admin.isNotEmpty) admin,
      if (country != null && country.isNotEmpty) country,
    ];

    return _ResolvedLocation(
      latitude: latitude,
      longitude: longitude,
      label: parts.join(', '),
    );
  }

  _ResolvedLocation? _resolveLocalLocation(
    String city, {
    required String language,
  }) {
    final normalized = _normalizeCityQuery(city);
    final key = _cityAliases[normalized] ?? normalized;
    final cityData = _localCityIndex[key];
    if (cityData == null) {
      return null;
    }

    final label = language == 'ru' ? cityData.labelRu : cityData.labelEn;
    return _ResolvedLocation(
      latitude: cityData.latitude,
      longitude: cityData.longitude,
      label: label,
    );
  }

  Future<http.Response> _getWithRetry(
    Uri uri, {
    required String errorKey,
  }) async {
    Object? lastError;

    for (int attempt = 0; attempt < 2; attempt++) {
      try {
        final response = await http
            .get(uri, headers: _clientHeader)
            .timeout(_requestTimeout);
        if (response.statusCode == 200) {
          return response;
        }
        lastError = WeatherLookupException(errorKey);
      } catch (error) {
        lastError = error;
      }
    }

    if (lastError is WeatherLookupException) {
      throw lastError;
    }
    throw WeatherLookupException(errorKey);
  }
}

String _normalizeCityQuery(String value) {
  final normalized = value
      .toLowerCase()
      .replaceAll('ё', 'е')
      .replaceAll('-', ' ')
      .replaceAll('.', ' ')
      .replaceAll(',', ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();

  final parts = normalized.split(' ');
  if (parts.length >= 2) {
    final withoutCountry = parts
        .where(
          (part) =>
              part != 'kz' &&
              part != 'kazakhstan' &&
              part != 'kazahstan' &&
              part != 'қазақстан' &&
              part != 'казахстан' &&
              part != 'kg' &&
              part != 'kyrgyzstan' &&
              part != 'киргизия' &&
              part != 'кыргызстан',
        )
        .join(' ');
    if (withoutCountry.isNotEmpty) {
      return withoutCountry;
    }
  }

  return normalized;
}

const _cityAliases = <String, String>{
  'астана': 'astana',
  'astana': 'astana',
  'nur sultan': 'astana',
  'нур султан': 'astana',
  'караганда': 'karaganda',
  'karaganda': 'karaganda',
  'алматы': 'almaty',
  'almaty': 'almaty',
  'алма ата': 'almaty',
  'alma ata': 'almaty',
  'боровое': 'burabay',
  'borovoe': 'burabay',
  'burabay': 'burabay',
  'burabay resort': 'burabay',
  'щучинск': 'burabay',
  'schuchinsk': 'burabay',
  'балхаш': 'balkhash',
  'balkhash': 'balkhash',
  'бишкек': 'bishkek',
  'bishkek': 'bishkek',
  'павлодар': 'pavlodar',
  'pavlodar': 'pavlodar',
  'темиртау': 'temirtau',
  'temirtau': 'temirtau',
  'капшагай': 'kapshagay',
  'kapshagay': 'kapshagay',
  'конаев': 'kapshagay',
  'konaev': 'kapshagay',
  'қонаев': 'kapshagay',
  'костанай': 'kostanay',
  'қостанай': 'kostanay',
  'kostanay': 'kostanay',
};

const _localCityIndex = <String, _KnownCity>{
  'astana': _KnownCity(
    latitude: 51.1694,
    longitude: 71.4491,
    labelRu: 'Астана, KZ',
    labelEn: 'Astana, KZ',
  ),
  'karaganda': _KnownCity(
    latitude: 49.8060,
    longitude: 73.0850,
    labelRu: 'Караганда, KZ',
    labelEn: 'Karaganda, KZ',
  ),
  'almaty': _KnownCity(
    latitude: 43.2389,
    longitude: 76.8897,
    labelRu: 'Алматы, KZ',
    labelEn: 'Almaty, KZ',
  ),
  'burabay': _KnownCity(
    latitude: 53.0838,
    longitude: 70.3136,
    labelRu: 'Бурабай, KZ',
    labelEn: 'Burabay, KZ',
  ),
  'balkhash': _KnownCity(
    latitude: 46.8481,
    longitude: 74.9950,
    labelRu: 'Балхаш, KZ',
    labelEn: 'Balkhash, KZ',
  ),
  'bishkek': _KnownCity(
    latitude: 42.8746,
    longitude: 74.5698,
    labelRu: 'Бишкек, KG',
    labelEn: 'Bishkek, KG',
  ),
  'pavlodar': _KnownCity(
    latitude: 52.2871,
    longitude: 76.9674,
    labelRu: 'Павлодар, KZ',
    labelEn: 'Pavlodar, KZ',
  ),
  'temirtau': _KnownCity(
    latitude: 50.0549,
    longitude: 72.9646,
    labelRu: 'Темиртау, KZ',
    labelEn: 'Temirtau, KZ',
  ),
  'kapshagay': _KnownCity(
    latitude: 43.8844,
    longitude: 77.0687,
    labelRu: 'Конаев, KZ',
    labelEn: 'Konaev, KZ',
  ),
  'kostanay': _KnownCity(
    latitude: 53.2145,
    longitude: 63.6246,
    labelRu: 'Костанай, KZ',
    labelEn: 'Kostanay, KZ',
  ),
};

class WeatherSnapshot {
  final String cityName;
  final double temperatureC;
  final double windSpeedKmh;
  final int weatherCode;
  final DateTime updatedAt;
  final List<HourlyForecast> hourly;

  const WeatherSnapshot({
    required this.cityName,
    required this.temperatureC,
    required this.windSpeedKmh,
    required this.weatherCode,
    required this.updatedAt,
    required this.hourly,
  });
}

class HourlyForecast {
  final DateTime time;
  final double temperatureC;
  final int rainChance;
  final int weatherCode;

  const HourlyForecast({
    required this.time,
    required this.temperatureC,
    required this.rainChance,
    required this.weatherCode,
  });
}

class _ResolvedLocation {
  final double latitude;
  final double longitude;
  final String label;

  const _ResolvedLocation({
    required this.latitude,
    required this.longitude,
    required this.label,
  });
}

class _KnownCity {
  final double latitude;
  final double longitude;
  final String labelRu;
  final String labelEn;

  const _KnownCity({
    required this.latitude,
    required this.longitude,
    required this.labelRu,
    required this.labelEn,
  });
}
