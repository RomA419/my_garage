import 'package:flutter/material.dart';

/// Список типов автомобилей, используемых в приложении.
///
/// Каждый тип включает:
/// - `name`: отображаемое имя
/// - `svg`: путь к SVG-ресурсу (используется для превью)
/// - `icon`: иконка (для списка и простого отображения)
const List<Map<String, dynamic>> carTypes = [
  {
    'name': 'Седан',
    'svg': 'assets/cars/car_sedan.svg',
    'png': 'assets/cars/car_sedan.png',
    'icon': Icons.directions_car_filled,
  },
  {
    'name': 'Универсал',
    'svg': 'assets/cars/car_wagon.svg',
    'png': 'assets/cars/car_wagon.png',
    'icon': Icons.directions_car,
  },
  {
    'name': 'Кабриолет',
    'svg': 'assets/cars/car_cabriolet.svg',
    'png': 'assets/cars/car_cabriolet.png',
    'icon': Icons.car_rental,
  },
  {
    'name': 'Купе',
    'svg': 'assets/cars/car_coupe.svg',
    'png': 'assets/cars/car_coupe.png',
    'icon': Icons.sports_motorsports,
  },
  {
    'name': 'Хэтчбек',
    'svg': 'assets/cars/car_hatchback.svg',
    'png': 'assets/cars/car_hatchback.png',
    'icon': Icons.directions_car_filled,
  },
  {
    'name': 'Минивэн',
    'svg': 'assets/cars/car_minivan.svg',
    'png': 'assets/cars/car_minivan.png',
    'icon': Icons.directions_bus,
  },
  {
    'name': 'Внедорожник',
    'svg': 'assets/cars/car_suv.svg',
    'png': 'assets/cars/car_suv.png',
    'icon': Icons.electric_car,
  },
  {
    'name': 'Пикап',
    'svg': 'assets/cars/car_truck.svg',
    'png': 'assets/cars/car_truck.png',
    'icon': Icons.local_shipping,
  },
  {
    'name': 'Фургон',
    'svg': 'assets/cars/car_van.svg',
    'png': 'assets/cars/car_van.png',
    'icon': Icons.fire_truck,
  },
];
