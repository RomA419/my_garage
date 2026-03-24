import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'garage_provider.dart';
import 'locale_service.dart';
import 'models.dart';

// ──────────────────────────────────────────────
//  Data models
// ──────────────────────────────────────────────
class _Problem {
  final IconData icon;
  final Color color;
  final String symptom;
  final String cause;
  final String solution;
  final String urgency; // 'high' | 'medium' | 'low'

  const _Problem({
    required this.icon,
    required this.color,
    required this.symptom,
    required this.cause,
    required this.solution,
    required this.urgency,
  });
}

class _MaintItem {
  final IconData icon;
  final String name;
  final String interval;
  final String note;

  const _MaintItem({
    required this.icon,
    required this.name,
    required this.interval,
    this.note = '',
  });
}

class _Tip {
  final IconData icon;
  final String text;

  const _Tip({required this.icon, required this.text});
}

class _Knowledge {
  final String about;
  final List<_Problem> problems;
  final List<_MaintItem> maint;
  final List<_Tip> tips;

  const _Knowledge({
    required this.about,
    required this.problems,
    required this.maint,
    this.tips = const [],
  });
}

// ──────────────────────────────────────────────
//  Maintenance intervals
// ──────────────────────────────────────────────
const _maintJapanese = <_MaintItem>[
  _MaintItem(icon: Icons.opacity, name: 'Моторное масло', interval: '5 000–10 000 км', note: 'Или раз в год'),
  _MaintItem(icon: Icons.air, name: 'Воздушный фильтр', interval: '15 000–30 000 км'),
  _MaintItem(icon: Icons.bolt, name: 'Свечи зажигания', interval: '30 000–60 000 км'),
  _MaintItem(icon: Icons.album, name: 'Тормозные колодки', interval: '30 000–50 000 км', note: 'Зависит от стиля езды'),
  _MaintItem(icon: Icons.water_drop, name: 'Охлаждающая жидкость', interval: '60 000 км / 5 лет'),
  _MaintItem(icon: Icons.settings, name: 'Ремень/цепь ГРМ', interval: '90 000–100 000 км', note: 'Для ременных ДВС обязательно'),
  _MaintItem(icon: Icons.car_repair, name: 'Масло АКПП/вариатора', interval: '60 000–80 000 км'),
  _MaintItem(icon: Icons.battery_charging_full, name: 'Аккумулятор', interval: '4–6 лет'),
];

const _maintKorean = <_MaintItem>[
  _MaintItem(icon: Icons.opacity, name: 'Моторное масло', interval: '7 500–10 000 км', note: 'Или раз в год'),
  _MaintItem(icon: Icons.air, name: 'Воздушный фильтр', interval: '20 000–30 000 км'),
  _MaintItem(icon: Icons.bolt, name: 'Свечи зажигания', interval: '30 000–60 000 км'),
  _MaintItem(icon: Icons.album, name: 'Тормозные колодки', interval: '30 000–50 000 км'),
  _MaintItem(icon: Icons.water_drop, name: 'Охлаждающая жидкость', interval: '60 000 км / 5 лет'),
  _MaintItem(icon: Icons.settings, name: 'Ремень ГРМ', interval: '60 000–100 000 км', note: 'Критично — требует проверки!'),
  _MaintItem(icon: Icons.sync, name: 'Масло АКПП / DSG', interval: '40 000–60 000 км', note: 'Важно для комфортной работы'),
  _MaintItem(icon: Icons.battery_charging_full, name: 'Аккумулятор', interval: '4–6 лет'),
];

const _maintGerman = <_MaintItem>[
  _MaintItem(icon: Icons.opacity, name: 'Моторное масло', interval: '10 000–15 000 км', note: 'Рекомендуется каждые 7 500 км'),
  _MaintItem(icon: Icons.air, name: 'Воздушный фильтр', interval: '20 000–40 000 км'),
  _MaintItem(icon: Icons.bolt, name: 'Свечи зажигания', interval: '30 000–60 000 км'),
  _MaintItem(icon: Icons.album, name: 'Тормозные колодки', interval: '30 000–50 000 км'),
  _MaintItem(icon: Icons.water_drop, name: 'Охлаждающая жидкость', interval: '60 000 км / 5 лет'),
  _MaintItem(icon: Icons.link, name: 'Цепь ГРМ', interval: 'По симптомам (150+ тыс. км)', note: '«Вечная» по заявлению, но требует контроля'),
  _MaintItem(icon: Icons.sync, name: 'Масло DSG / АКПП', interval: '40 000–60 000 км'),
  _MaintItem(icon: Icons.battery_charging_full, name: 'Аккумулятор', interval: '4–5 лет', note: 'Важна кодировка при замене'),
];

const _maintGeneric = <_MaintItem>[
  _MaintItem(icon: Icons.opacity, name: 'Моторное масло', interval: '5 000–10 000 км'),
  _MaintItem(icon: Icons.air, name: 'Воздушный фильтр', interval: '15 000–30 000 км'),
  _MaintItem(icon: Icons.bolt, name: 'Свечи зажигания', interval: '30 000–50 000 км'),
  _MaintItem(icon: Icons.album, name: 'Тормозные колодки', interval: '25 000–50 000 км'),
  _MaintItem(icon: Icons.water_drop, name: 'Охлаждающая жидкость', interval: '60 000 км / 5 лет'),
  _MaintItem(icon: Icons.settings, name: 'Ремень/цепь ГРМ', interval: '60 000–100 000 км'),
  _MaintItem(icon: Icons.battery_charging_full, name: 'Аккумулятор', interval: '4–6 лет'),
];

// ──────────────────────────────────────────────
//  Tips
// ──────────────────────────────────────────────
const _tipsGeneral = <_Tip>[
  _Tip(icon: Icons.thermostat, text: 'Прогревайте двигатель 3–5 минут в морозную погоду перед началом движения'),
  _Tip(icon: Icons.water_drop, text: 'Используйте только рекомендованное произ­водителем моторное масло и охлаждающую жидкость'),
  _Tip(icon: Icons.circle_outlined, text: 'Проверяйте давление в шинах каждые 2–4 недели и перед длительными поездками'),
  _Tip(icon: Icons.volume_up, text: 'Не игнорируйте посторонние звуки — стуки, скрипы и вибрации сигнализируют о проблеме'),
  _Tip(icon: Icons.local_car_wash, text: 'Мойте автомобиль зимой не реже раза в неделю — дорожная соль разрушает кузов'),
];

const _tipsToyota = <_Tip>[
  _Tip(icon: Icons.opacity, text: 'Меняйте масло каждые 5 000 км — не доверяйте инструкции «10 000 км» для условий СНГ'),
  _Tip(icon: Icons.water_drop, text: 'Заменяйте охлаждающую жидкость Toyota Super Long Life Coolant строго каждые 60 000 км'),
  _Tip(icon: Icons.rotate_right, text: 'При каждом ТО проверяйте пыльники ШРУСа — трещина в пыльнике = скорая замена ШРУСа'),
  _Tip(icon: Icons.battery_charging_full, text: 'Меняйте аккумулятор каждые 3 года профилактически, не дожидаясь отказа в мороз'),
];

const _tipsKorean = <_Tip>[
  _Tip(icon: Icons.sync, text: 'Меняйте масло в АКПП/DSG каждые 40 000 км — производитель занижает интервалы'),
  _Tip(icon: Icons.ac_unit, text: 'Делайте антибактериальную чистку испарителя кондиционера раз в год'),
  _Tip(icon: Icons.opacity, text: 'Для двигателей 1.6T/2.0T используйте масло 5W-30 с допуском ACEA C3'),
  _Tip(icon: Icons.car_repair, text: 'Проверяйте ремень ГРМ каждые 60 000 км — на ранних Hyundai/Kia его обрыв = капремонт'),
];

const _tipsGerman = <_Tip>[
  _Tip(icon: Icons.build, text: 'При замене АКБ на BMW/Mercedes обязательно делайте кодировку через диагностический сканер'),
  _Tip(icon: Icons.opacity, text: 'Меняйте масло каждые 7 500 км — не ждите индикатора Service (он занижен в СНГ условиях)'),
  _Tip(icon: Icons.local_fire_department, text: 'Регулярно проверяйте уровень ОЖ — пластиковые патрубки BMW склонны к трещинам'),
  _Tip(icon: Icons.sync, text: 'DSG/S-Tronic нуждается в замене масла каждые 40–60 тыс. км — игнорирование ведёт к дорогому ремонту'),
];

// ──────────────────────────────────────────────
//  Knowledge database (brand / brand+model keys — lowercase)
// ──────────────────────────────────────────────
const _db = <String, _Knowledge>{
  // ─── Toyota ───
  'toyota': _Knowledge(
    about: 'Toyota — один из самых надёжных японских брендов. Ресурс двигателей 400–600 тыс. км при правильном обслуживании. Широкая сеть, доступные запчасти.',
    problems: [
      _Problem(
        icon: Icons.disc_full, color: Color(0xFFFF9800),
        symptom: 'Вибрация при торможении',
        cause: 'Коробление или износ тормозных дисков',
        solution: 'Замена тормозных дисков и колодок в паре. При небольшом короблении дисков возможна проточка.',
        urgency: 'medium',
      ),
      _Problem(
        icon: Icons.rotate_right, color: Color(0xFFF44336),
        symptom: 'Хруст/стук при повороте руля',
        cause: 'Износ пыльника или ШРУСа полуоси',
        solution: 'Проверить пыльники. При целом пыльнике — набить смазку. При порванном — немедленная замена ШРУСа.',
        urgency: 'high',
      ),
      _Problem(
        icon: Icons.local_gas_station, color: Color(0xFFFFC107),
        symptom: 'Повышенный расход топлива',
        cause: 'Засорён воздушный/топливный фильтр или форсунки',
        solution: 'Заменить воздушный фильтр. Промыть форсунки (ультразвук). Заменить топливный фильтр.',
        urgency: 'low',
      ),
      _Problem(
        icon: Icons.ac_unit, color: Color(0xFF2196F3),
        symptom: 'Тяжёлый/долгий запуск в мороз',
        cause: 'Слабый аккумулятор или загустевшее масло',
        solution: 'Проверить АКБ нагрузочной вилкой. Заменить при ёмкости <80%. Перейти на масло 0W-30 зимой.',
        urgency: 'medium',
      ),
    ],
    maint: _maintJapanese,
    tips: _tipsToyota,
  ),

  'toyota camry': _Knowledge(
    about: 'Toyota Camry XV70 (2.5 л 2AR-FE) — флагман бизнес-класса в СНГ. Двигатель надёжен, но чувствителен к качеству масла и срокам обслуживания.',
    problems: [
      _Problem(
        icon: Icons.settings, color: Color(0xFFFF9800),
        symptom: 'Вибрация двигателя на холостом ходу',
        cause: 'Закоксовка дроссельной заслонки или нагар на форсунках',
        solution: 'Чистка дроссельной заслонки. Замена свечей зажигания (оригинал NGK). Промывка форсунок.',
        urgency: 'low',
      ),
      _Problem(
        icon: Icons.opacity, color: Color(0xFFFFC107),
        symptom: 'Пятна масла под машиной спереди',
        cause: 'Износ прокладки клапанной крышки ГБЦ',
        solution: 'Замена прокладки клапанной крышки. Затяжка строго по моменту по схеме из мануала.',
        urgency: 'medium',
      ),
      _Problem(
        icon: Icons.vibration, color: Color(0xFFFF5722),
        symptom: 'Стук/толчок спереди на скорости',
        cause: 'Износ подушек (опор) двигателя',
        solution: 'Проверить все 3–4 опоры двигателя. При трещинах — замена в сборе.',
        urgency: 'medium',
      ),
      _Problem(
        icon: Icons.disc_full, color: Color(0xFFFF9800),
        symptom: 'Вибрация руля при торможении',
        cause: 'Коробление тормозных дисков (частое на XV70)',
        solution: 'Замена дисков (TRD, Brembo) + колодок Akebono или TRD. Проточка дисков не рекомендуется.',
        urgency: 'medium',
      ),
    ],
    maint: _maintJapanese,
    tips: _tipsToyota,
  ),

  'toyota rav4': _Knowledge(
    about: 'Toyota RAV4 пятого поколения (двигатель 2.0 M20A-FKS). Надёжный кроссовер с полным приводом. Двигатель чувствителен к качеству масла.',
    problems: [
      _Problem(
        icon: Icons.opacity, color: Color(0xFFFF9800),
        symptom: 'Повышенный масляный аппетит',
        cause: 'Особенность двигателей серии M20A на начальных пробегах',
        solution: 'Проверять уровень масла каждые 3 000 км. Применять только 0W-20 или 0W-16 с одобрением Toyota.',
        urgency: 'medium',
      ),
      _Problem(
        icon: Icons.vibration, color: Color(0xFFF44336),
        symptom: 'Рывки/подёргивания вариатора',
        cause: 'Загрязнённое масло CVT или начальный износ ремня',
        solution: 'Замена масла CVT оригинальной жидкостью Toyota CVT Fluid FE. Только оригинал — аналоги не подходят.',
        urgency: 'high',
      ),
      _Problem(
        icon: Icons.rotate_right, color: Color(0xFFF44336),
        symptom: 'Щелчки при вывернутом руле',
        cause: 'Начальный износ внешнего ШРУСа',
        solution: 'Проверить пыльники при каждом ТО. При трещинах в пыльнике — немедленная замена ШРУСа.',
        urgency: 'high',
      ),
    ],
    maint: _maintJapanese,
    tips: _tipsToyota,
  ),

  'toyota land cruiser': _Knowledge(
    about: 'Toyota Land Cruiser 200/300 — легендарный рамный внедорожник. Ресурс 500+ тыс. км, но дизельный мотор требует качественного топлива и масла.',
    problems: [
      _Problem(
        icon: Icons.opacity, color: Color(0xFFF44336),
        symptom: 'Расход масла и дым из выхлопа',
        cause: 'Износ маслосъёмных колпачков (дизель 1VD-FTV)',
        solution: 'Замена маслосъёмных колпачков. Работа дорогостоящая — требует частичной разборки ДВС.',
        urgency: 'high',
      ),
      _Problem(
        icon: Icons.settings, color: Color(0xFFFF9800),
        symptom: 'Скрежет/хруст раздаточной коробки',
        cause: 'Износ крестовин карданных валов',
        solution: 'Замена крестовин карданных валов. Профилактически смазывать каждые 30 000 км.',
        urgency: 'medium',
      ),
      _Problem(
        icon: Icons.local_gas_station, color: Color(0xFFFFC107),
        symptom: 'Потеря мощности, чёрный дым (дизель)',
        cause: 'Засорение сажевого фильтра или форсунок',
        solution: 'Регенерация сажевого фильтра (принудительная). Промывка форсунок Common Rail.',
        urgency: 'medium',
      ),
    ],
    maint: _maintJapanese,
    tips: _tipsToyota,
  ),

  // ─── Kia ───
  'kia': _Knowledge(
    about: 'Kia (Hyundai Motor Group) — корейский бренд с современными моторами и АКПП/DSG. Требует строгого соблюдения интервалов замены масла в коробке.',
    problems: [
      _Problem(
        icon: Icons.sync, color: Color(0xFFF44336),
        symptom: 'Рывки и толчки при переключении АКПП',
        cause: 'Загрязнённое масло в АКПП или ДКП (DCT 7-ступ.)',
        solution: 'Срочная замена масла АКПП с промывкой. Только оригинальная Hyundai/Kia ATF SP-IV-M.',
        urgency: 'high',
      ),
      _Problem(
        icon: Icons.album, color: Color(0xFFFF9800),
        symptom: 'Скрип тормозов при торможении',
        cause: 'Износ тормозных колодок до датчика',
        solution: 'Замена тормозных колодок. Проверить диски — при канавках глубже 2 мм заменить диски.',
        urgency: 'medium',
      ),
      _Problem(
        icon: Icons.ac_unit, color: Color(0xFF2196F3),
        symptom: 'Неприятный запах при включении кондиционера',
        cause: 'Грибок и бактерии на испарителе кондиционера',
        solution: 'Антибактериальная чистка испарителя спреем. Замена фильтра салона (каждые 15 000 км).',
        urgency: 'low',
      ),
      _Problem(
        icon: Icons.rotate_right, color: Color(0xFFF44336),
        symptom: 'Стук рулевого управления на кочках',
        cause: 'Износ электрорулевой рейки',
        solution: 'Диагностика ЭУР. Как правило, требуется замена рулевой рейки в сборе или её ремонт.',
        urgency: 'high',
      ),
    ],
    maint: _maintKorean,
    tips: _tipsKorean,
  ),

  // ─── Hyundai ───
  'hyundai': _Knowledge(
    about: 'Hyundai разделяет платформу с Kia. Двигатели Nu, Theta II, Smartstream — современные и мощные. Особого внимания требует АКПП/DCT.',
    problems: [
      _Problem(
        icon: Icons.vibration, color: Color(0xFFFFC107),
        symptom: 'Тряска/вибрация двигателя на хол. ходу',
        cause: 'Износ опор (подушек) двигателя',
        solution: 'Замена подушек двигателя (передней, задней, боковой). При вибрации на скорости — доп. диагностика.',
        urgency: 'medium',
      ),
      _Problem(
        icon: Icons.trending_down, color: Color(0xFFFF9800),
        symptom: 'Потеря мощности, вялый разгон',
        cause: 'Засорение впуска/дросселя или проблема турбины (1.6T)',
        solution: 'Чистка дроссельной заслонки. Для 1.6T — дополнительная проверка турбокомпрессора (характерный свист).',
        urgency: 'medium',
      ),
      _Problem(
        icon: Icons.opacity, color: Color(0xFFF44336),
        symptom: 'Масло уходит — расход >0.5 л/1000 км',
        cause: 'Износ маслосъёмных колпачков (Theta II 2.0/2.4)',
        solution: 'Замена маслосъёмных колпачков. Требует частичной разборки ГБЦ — дорогостоящая работа.',
        urgency: 'high',
      ),
      _Problem(
        icon: Icons.sync, color: Color(0xFFF44336),
        symptom: 'Рывки / «пинки» DCT при старте',
        cause: 'Износ или перегрев фрикционов DCT 7DCT',
        solution: 'Замена масла DCT оригинальной жидкостью. При прогрессии — ремонт или замена мехатроника DCT.',
        urgency: 'high',
      ),
    ],
    maint: _maintKorean,
    tips: _tipsKorean,
  ),

  // ─── Chevrolet ───
  'chevrolet': _Knowledge(
    about: 'Chevrolet (GM) в СНГ — Cobalt, Onix, Lacetti. Простые, дешёвые в обслуживании, широкий выбор запчастей на любом рынке.',
    problems: [
      _Problem(
        icon: Icons.vibration, color: Color(0xFFFF9800),
        symptom: 'Вибрация при наборе скорости',
        cause: 'Износ ШРУСа или подвесного подшипника карданного вала',
        solution: 'Замена пыльника/ШРУСа передней полуоси. Для заднеприводных — диагностика карданного вала.',
        urgency: 'medium',
      ),
      _Problem(
        icon: Icons.settings, color: Color(0xFFFFC107),
        symptom: 'Плавающие обороты двигателя',
        cause: 'Закоксовка дроссельной заслонки или клапана ХХ',
        solution: 'Чистка дросселя снятием. Сброс адаптаций ЭБУ (отсоединить АКБ на 10 мин).',
        urgency: 'low',
      ),
      _Problem(
        icon: Icons.opacity, color: Color(0xFFFFC107),
        symptom: 'Капли масла под двигателем',
        cause: 'Износ сальника коленвала или прокладки поддона',
        solution: 'Замена сальника переднего коленвала и/или прокладки поддона. Доступные запчасти.',
        urgency: 'medium',
      ),
      _Problem(
        icon: Icons.rotate_right, color: Color(0xFFFF9800),
        symptom: 'Стук рулевых тяг на кочках',
        cause: 'Износ рулевых наконечников или шаровых опор',
        solution: 'Замена рулевых наконечников / шаровых опор. Обязательная сход-развал после замены.',
        urgency: 'medium',
      ),
    ],
    maint: _maintGeneric,
    tips: _tipsGeneral,
  ),

  // ─── Lada ───
  'lada': _Knowledge(
    about: 'Lada (АвтоВАЗ) — самые доступные авто рынка. Простая конструкция позволяет самостоятельно выполнять большинство ремонтных работ.',
    problems: [
      _Problem(
        icon: Icons.vibration, color: Color(0xFFFFC107),
        symptom: 'Стук/вибрация кузова или педалей',
        cause: 'Ослабление болтов подрамника или кронштейнов кузова',
        solution: 'Протяжка болтов подрамника и кузовных кронштейнов по крутящему моменту (100–150 Нм).',
        urgency: 'medium',
      ),
      _Problem(
        icon: Icons.settings, color: Color(0xFFFF9800),
        symptom: 'Нестабильный холостой ход',
        cause: 'Засорение дроссельной заслонки или датчика МАФ (для инжекторных)',
        solution: 'Чистка ДЗ и очистка датчика воздуха карбклинером. Адаптация ДЗ после чистки.',
        urgency: 'low',
      ),
      _Problem(
        icon: Icons.opacity, color: Color(0xFFFFC107),
        symptom: 'Течь масла из-под клапанной крышки',
        cause: 'Износ прокладки крышки ГБЦ',
        solution: 'Замена прокладки клапанной крышки. Недорогая работа — прокладка стоит дёшево.',
        urgency: 'medium',
      ),
      _Problem(
        icon: Icons.directions_car, color: Color(0xFFFF9800),
        symptom: 'Стук/шум задней подвески',
        cause: 'Износ задних амортизаторов или пружин',
        solution: 'Замена амортизаторов задней подвески (LYNXauto, SATO, Bilstein). Проверить отбойники.',
        urgency: 'medium',
      ),
    ],
    maint: _maintGeneric,
    tips: _tipsGeneral,
  ),

  // ─── BMW ───
  'bmw': _Knowledge(
    about: 'BMW — немецкий премиум-бренд с акцентом на спортивное вождение. Высокая стоимость обслуживания, но непревзойдённая управляемость класса.',
    problems: [
      _Problem(
        icon: Icons.local_fire_department, color: Color(0xFFF44336),
        symptom: 'Течь или перерасход охлаждающей жидкости',
        cause: 'Растрескивание пластиковых патрубков и расширительного бачка (типичная болячка N52/N54)',
        solution: 'Профилактическая замена патрубков СО и расширительного бачка при 80–100 тыс. км. Не откладывать.',
        urgency: 'high',
      ),
      _Problem(
        icon: Icons.link, color: Color(0xFFF44336),
        symptom: 'Стук из ГРМ при запуске / на хол. ходу',
        cause: 'Растяжение цепи ГРМ — критично для N47, N54, N55, N20',
        solution: 'Срочная замена цепного привода ГРМ (цепь, натяжители, направляющие). Промедление = капремонт.',
        urgency: 'high',
      ),
      _Problem(
        icon: Icons.audiotrack, color: Color(0xFFFF9800),
        symptom: 'Вой / завывание моторного отсека',
        cause: 'Износ электрической водяной помпы (N52, N54)',
        solution: 'Замена водяной помпы и термостата (желательно одновременно). Профилактически каждые 80–100 тыс. км.',
        urgency: 'high',
      ),
      _Problem(
        icon: Icons.vibration, color: Color(0xFFFFC107),
        symptom: 'Вибрация руля на скорости 80–120 км/ч',
        cause: 'Износ колёсных подшипников или дисбаланс колёс',
        solution: 'Балансировка и стенд. Если не помогло — замена ступичных подшипников спереди.',
        urgency: 'medium',
      ),
    ],
    maint: _maintGerman,
    tips: _tipsGerman,
  ),

  // ─── Mercedes ───
  'mercedes': _Knowledge(
    about: 'Mercedes-Benz — синоним роскоши и технологий. Высококачественная постройка, но сложная электроника требует специализированного СТО.',
    problems: [
      _Problem(
        icon: Icons.airline_seat_recline_extra, color: Color(0xFFF44336),
        symptom: 'Автомобиль «садится» — оседает подвеска',
        cause: 'Износ пневматических баллонов или компрессора Airmatic',
        solution: 'Замена пневмостоек (или конвертация на пружины). Использовать качественный аналог или оригинал.',
        urgency: 'high',
      ),
      _Problem(
        icon: Icons.opacity, color: Color(0xFFF44336),
        symptom: 'Сизый дым, расход масла >0.5 л/1000 км',
        cause: 'Износ маслосъёмных колпачков (OM642, M272/M273)',
        solution: 'Ремонт ГБЦ с заменой маслосъёмных колпачков. Дорогостоящая и длительная работа.',
        urgency: 'high',
      ),
      _Problem(
        icon: Icons.directions_car, color: Color(0xFFFF9800),
        symptom: 'Скрип/стук передней подвески',
        cause: 'Износ передних рычагов и сайлентблоков',
        solution: 'Замена рычагов в сборе. Рекомендуются усиленные MEYLE HD или качественные OEM-аналоги.',
        urgency: 'medium',
      ),
      _Problem(
        icon: Icons.link, color: Color(0xFFF44336),
        symptom: 'Стук при запуске/остановке двигателя',
        cause: 'Износ цепи ГРМ или натяжителя',
        solution: 'Диагностика с ДСТ-сканером. При подтверждении — замена цепного привода ГРМ.',
        urgency: 'high',
      ),
    ],
    maint: _maintGerman,
    tips: _tipsGerman,
  ),

  'mercedes-benz': _Knowledge(
    about: 'Mercedes-Benz — синоним роскоши и технологий. Сложная электроника требует фирменного оборудования при диагностике.',
    problems: [
      _Problem(
        icon: Icons.airline_seat_recline_extra, color: Color(0xFFF44336),
        symptom: 'Автомобиль «садится» на пневмоподвеске',
        cause: 'Износ пневмобаллонов или отказ компрессора Airmatic',
        solution: 'Замена пневмостоек или конвертация на обычные пружины. Компрессор — замена или ремонт.',
        urgency: 'high',
      ),
      _Problem(
        icon: Icons.link, color: Color(0xFFF44336),
        symptom: 'Стук при холодном запуске',
        cause: 'Износ цепи ГРМ или натяжителя',
        solution: 'Диагностика, замена цепного привода ГРМ. На дизелях OM651 — срочно.',
        urgency: 'high',
      ),
    ],
    maint: _maintGerman,
    tips: _tipsGerman,
  ),

  // ─── Volkswagen ───
  'volkswagen': _Knowledge(
    about: 'Volkswagen — «народный автомобиль» с высококачественной сборкой. Двигатели TSI хороши, но DSG и ремень ГРМ требуют строгого регламента.',
    problems: [
      _Problem(
        icon: Icons.sync_problem, color: Color(0xFFF44336),
        symptom: 'Вибрация/рывки при старте и при 1–2 передаче',
        cause: 'Износ фрикционов сухого DSG (DQ200 — 7-ступ.)',
        solution: 'Обновление прошивки мехатроника у дилера. При прогрессии — замена/ремонт мехатроника.',
        urgency: 'high',
      ),
      _Problem(
        icon: Icons.build, color: Color(0xFFF44336),
        symptom: 'Стук при запуске и остановке дизельного мотора',
        cause: 'Износ двойного маховика (болячка 2.0 TDI с DSG)',
        solution: 'Замена двойного маховика и сцепления одновременно. Дорогостоящая работа, но необходима.',
        urgency: 'high',
      ),
      _Problem(
        icon: Icons.trending_down, color: Color(0xFFFF9800),
        symptom: 'Потеря мощности, свист из-под капота',
        cause: 'Износ турбины или утечка в патрубке интеркулера',
        solution: 'Проверить патрубки интеркулера на трещины. Если OK — диагностика турбокомпрессора.',
        urgency: 'high',
      ),
      _Problem(
        icon: Icons.local_gas_station, color: Color(0xFFFFC107),
        symptom: 'Закоксовка клапанов (1.4 TSI, 1.8 TSI)',
        cause: 'Прямой впрыск не омывает клапаны — нагар образуется быстрее',
        solution: 'Чистка впускных клапанов вальцовкой или химическим методом каждые 60–80 тыс. км.',
        urgency: 'medium',
      ),
    ],
    maint: _maintGerman,
    tips: _tipsGerman,
  ),

  // ─── Subaru ───
  'subaru': _Knowledge(
    about: 'Subaru — японский бренд с оппозитными (боксёрными) двигателями и постоянным AWD. Надёжная трансмиссия, но ДВС имеет характерные слабые места.',
    problems: [
      _Problem(
        icon: Icons.opacity, color: Color(0xFFFF9800),
        symptom: 'Течь масла по бокам двигателя',
        cause: 'Износ прокладок клапанных крышек (характерно для EJ20/EJ25)',
        solution: 'Замена прокладок крышек. Желательно комбинировать с заменой ремня ГРМ.',
        urgency: 'medium',
      ),
      _Problem(
        icon: Icons.local_fire_department, color: Color(0xFFF44336),
        symptom: 'Перегрев, белый дым, ОЖ уходит',
        cause: 'Пробой прокладки ГБЦ — типичная болячка EJ25',
        solution: 'Замена прокладки ГБЦ с новыми болтами. Не игнорировать — ведёт к капремонту.',
        urgency: 'high',
      ),
      _Problem(
        icon: Icons.sync, color: Color(0xFFF44336),
        symptom: 'Рывки и скачки оборотов вариатора',
        cause: 'Износ ремня или загрязнение жидкости CVT',
        solution: 'Замена жидкости CVT строго оригинальной (Subaru ECVT Fluid) каждые 30 000 км.',
        urgency: 'high',
      ),
    ],
    maint: _maintJapanese,
    tips: _tipsToyota,
  ),

  // ─── Lexus ───
  'lexus': _Knowledge(
    about: 'Lexus — премиальный бренд Toyota. Сочетает японскую надёжность Toyota с роскошным оснащением. Обслуживание дороже, но значительно реже.',
    problems: [
      _Problem(
        icon: Icons.opacity, color: Color(0xFFFFC107),
        symptom: 'Небольшое замасливание снизу (V6 3.5)',
        cause: 'Плановая замена сальников коленвала на пробеге 150+ тыс. км',
        solution: 'Замена сальника переднего и заднего коленвала. Недорогая профилактическая работа.',
        urgency: 'low',
      ),
      _Problem(
        icon: Icons.battery_charging_full, color: Color(0xFFFF9800),
        symptom: 'Деградация гибридной батареи (RX/ES Hybrid)',
        cause: 'Появляется после 150–200 тыс. км, характерно для гибридов',
        solution: 'Замена или восстановление гибридной батареи. Оригинал или восстановленный пакет у специалистов.',
        urgency: 'medium',
      ),
    ],
    maint: _maintJapanese,
    tips: _tipsToyota,
  ),

  // ─── Honda ───
  'honda': _Knowledge(
    about: 'Honda — ещё один столп японской надёжности. Двигатели серий R, K и L прославились высоким ресурсом. Вариатор CVT требует чёткого соблюдения интервалов.',
    problems: [
      _Problem(
        icon: Icons.sync, color: Color(0xFFF44336),
        symptom: 'Рывки вариатора, «пинки»',
        cause: 'Загрязнение жидкости CVT или износ ремня',
        solution: 'Замена жидкости CVT строго оригинальной Honda HCF-2 каждые 30–40 тыс. км.',
        urgency: 'high',
      ),
      _Problem(
        icon: Icons.opacity, color: Color(0xFFFFC107),
        symptom: 'Масляные пятна под капотом у 1.5T',
        cause: 'Небольшая течь из-под прокладки КПП или крышки ГБЦ',
        solution: 'Проверить прокладки. Замена при необходимости. Стандартная плановая работа.',
        urgency: 'medium',
      ),
    ],
    maint: _maintJapanese,
    tips: _tipsToyota,
  ),

  // ─── Nissan ───
  'nissan': _Knowledge(
    about: 'Nissan — японский бренд с широкой гаммой вариаторов (CVT) и надёжных двигателей серий QR и MR. Особого внимания требует вариатор.',
    problems: [
      _Problem(
        icon: Icons.sync, color: Color(0xFFF44336),
        symptom: 'Вибрация, пробуксовка вариатора',
        cause: 'Перегрев или износ ремня вариатора JF011E/JF015E',
        solution: 'Замена жидкости CVT (NS-3, NS-2) каждые 30 000 км. При прогрессии — ремонт/замена вариатора.',
        urgency: 'high',
      ),
      _Problem(
        icon: Icons.local_gas_station, color: Color(0xFFFFC107),
        symptom: 'Расход топлива вырос на 10–20%',
        cause: 'Засорение форсунок или воздушного фильтра',
        solution: 'Замена воздушного фильтра. Промывка топливных форсунок.',
        urgency: 'low',
      ),
    ],
    maint: _maintJapanese,
    tips: _tipsToyota,
  ),

  // ─── Mitsubishi ───
  'mitsubishi': _Knowledge(
    about: 'Mitsubishi — надёжный японский бренд. Трансмиссия Super Select 4WD — одна из лучших в классе. Двигатели 4B12/6B31 отличаются высоким ресурсом.',
    problems: [
      _Problem(
        icon: Icons.sync, color: Color(0xFFFF9800),
        symptom: 'Вибрация вариатора Jatco',
        cause: 'Загрязнение жидкости CVT Jatco',
        solution: 'Замена жидкости CVT (CVTF-J4 или NS-3) каждые 30 000 км. Только оригинал.',
        urgency: 'medium',
      ),
      _Problem(
        icon: Icons.settings, color: Color(0xFFFFC107),
        symptom: 'Стук переднего привода на льду',
        cause: 'Износ ШРУСа или вискомуфты',
        solution: 'Диагностика системы 4WD. Проверить пыльники привода.',
        urgency: 'medium',
      ),
    ],
    maint: _maintJapanese,
    tips: _tipsToyota,
  ),

  // ─── Generic fallback ───
  '_generic': _Knowledge(
    about: 'Общие рекомендации по диагностике и обслуживанию автомобиля. Для точных данных добавьте марку и модель авто.',
    problems: [
      _Problem(
        icon: Icons.warning_amber, color: Color(0xFFFFC107),
        symptom: 'Горит индикатор Check Engine',
        cause: 'Различные неисправности: датчики, катализатор, топливная система',
        solution: 'Считать коды ошибок OBD2 сканером. По кодам определить причину и устранить.',
        urgency: 'medium',
      ),
      _Problem(
        icon: Icons.thermostat, color: Color(0xFFF44336),
        symptom: 'Перегрев двигателя (стрелка темп. уходит вправо)',
        cause: 'Низкий уровень ОЖ, неисправный термостат или отказ вентилятора радиатора',
        solution: 'Остановиться немедленно! Проверить уровень ОЖ. При норме — диагностика термостата/вентилятора.',
        urgency: 'high',
      ),
      _Problem(
        icon: Icons.cloud_queue, color: Color(0xFF9E9E9E),
        symptom: 'Дым из выхлопной трубы',
        cause: 'Белый = ОЖ в цилиндрах, Синий = масло сгорает, Чёрный = богатая смесь',
        solution: 'Белый — проверить прокладку ГБЦ. Синий — маслосъёмные колпачки/кольца. Чёрный — форсунки/датчики.',
        urgency: 'high',
      ),
      _Problem(
        icon: Icons.vibration, color: Color(0xFFFF9800),
        symptom: 'Стуки и шумы в подвеске',
        cause: 'Износ амортизаторов, сайлентблоков, шаровых или стоек стабилизатора',
        solution: 'Диагностика подвески на подъёмнике. Метод «покачивания» для определения изношенного узла.',
        urgency: 'medium',
      ),
    ],
    maint: _maintGeneric,
  ),
};

// ──────────────────────────────────────────────
//  Page
// ──────────────────────────────────────────────
class CarAssistantPage extends StatefulWidget {
  const CarAssistantPage({super.key});

  @override
  State<CarAssistantPage> createState() => _CarAssistantPageState();
}

class _CarAssistantPageState extends State<CarAssistantPage>
    with SingleTickerProviderStateMixin {
  int? _selectedCarIndex;
  late TabController _tabController;
  final Set<int> _expanded = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  _Knowledge _getKnowledge(CarModel? car) {
    if (car == null) return _db['_generic']!;
    final brandModel = '${car.brand} ${car.type}'.toLowerCase().trim();
    final brand = car.brand.toLowerCase().trim();
    return _db[brandModel] ?? _db[brand] ?? _db['_generic']!;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final garage = context.watch<GarageProvider>();
    final cars = garage.cars;

    final effectiveIndex = _selectedCarIndex ??
        (cars.isEmpty ? null : garage.currentCarIndex.clamp(0, cars.length - 1));
    final selectedCar =
        (effectiveIndex != null && effectiveIndex < cars.length) ? cars[effectiveIndex] : null;
    final knowledge = _getKnowledge(selectedCar);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          LocaleService.tr('assistantTitle'),
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        backgroundColor: theme.appBarTheme.backgroundColor,
        iconTheme: theme.appBarTheme.iconTheme,
      ),
      body: cars.isEmpty
          ? _buildNoCar(theme)
          : Column(
              children: [
                // Car selector (only if >1 car)
                if (cars.length > 1)
                  _buildCarSelector(theme, isDark, cars, effectiveIndex),

                // Car info header
                _buildCarHeader(theme, isDark, selectedCar, knowledge),

                // Tabs
                TabBar(
                  controller: _tabController,
                  labelColor: theme.colorScheme.primary,
                  unselectedLabelColor:
                      theme.textTheme.bodySmall?.color?.withOpacity(0.6),
                  indicatorColor: theme.colorScheme.primary,
                  tabs: [
                    Tab(text: LocaleService.tr('assistantProblems')),
                    Tab(text: LocaleService.tr('assistantMaint')),
                    Tab(text: LocaleService.tr('assistantTips')),
                  ],
                ),

                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildProblemsTab(theme, isDark, knowledge),
                      _buildMaintTab(theme, isDark, knowledge),
                      _buildTipsTab(theme, isDark, knowledge),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  // ── No car ──────────────────────────────────
  Widget _buildNoCar(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.directions_car_outlined,
              size: 70, color: theme.colorScheme.primary.withOpacity(0.3)),
          const SizedBox(height: 14),
          Text(LocaleService.tr('assistantNoCar'),
              style: theme.textTheme.titleMedium),
          const SizedBox(height: 6),
          Text(LocaleService.tr('assistantNoCarHint'),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.textTheme.bodySmall?.color?.withOpacity(0.5),
              )),
        ],
      ),
    );
  }

  // ── Car selector row ────────────────────────
  Widget _buildCarSelector(
      ThemeData theme, bool isDark, List<CarModel> cars, int? selectedIndex) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16, top: 12, bottom: 4),
          child: Text(
            LocaleService.tr('assistantSelectCar'),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.textTheme.bodySmall?.color?.withOpacity(0.55),
              fontSize: 10,
              letterSpacing: 1.2,
            ),
          ),
        ),
        SizedBox(
          height: 46,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            itemCount: cars.length,
            itemBuilder: (_, i) {
              final car = cars[i];
              final selected = i == selectedIndex;
              return GestureDetector(
                onTap: () => setState(() {
                  _selectedCarIndex = i;
                  _expanded.clear();
                }),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 5),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: selected
                        ? theme.colorScheme.primary.withOpacity(0.15)
                        : (isDark
                            ? const Color(0xFF1E1E1E)
                            : Colors.grey.shade100),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: selected
                          ? theme.colorScheme.primary
                          : theme.dividerColor.withOpacity(0.3),
                      width: selected ? 1.5 : 1,
                    ),
                  ),
                  child: Text(
                    car.number.isNotEmpty ? car.number : car.title,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight:
                          selected ? FontWeight.bold : FontWeight.normal,
                      color: selected
                          ? theme.colorScheme.primary
                          : theme.textTheme.bodyMedium?.color,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ── Car info header ──────────────────────────
  Widget _buildCarHeader(
      ThemeData theme, bool isDark, CarModel? car, _Knowledge knowledge) {
    if (car == null) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Color(car.color).withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.directions_car_filled,
                color: Color(car.color), size: 28),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(car.title,
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.bold)),
                if (car.number.isNotEmpty)
                  Text(car.number,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color:
                            theme.textTheme.bodySmall?.color?.withOpacity(0.6),
                      )),
                const SizedBox(height: 5),
                Text(
                  knowledge.about,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color:
                        theme.textTheme.bodySmall?.color?.withOpacity(0.72),
                    fontSize: 11,
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Problems tab ────────────────────────────
  Widget _buildProblemsTab(
      ThemeData theme, bool isDark, _Knowledge knowledge) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: knowledge.problems.length,
      itemBuilder: (_, i) {
        final p = knowledge.problems[i];
        final expanded = _expanded.contains(i);
        final urgencyColor = p.urgency == 'high'
            ? Colors.red
            : p.urgency == 'medium'
                ? Colors.orange
                : Colors.green;
        final urgencyLabel = p.urgency == 'high'
            ? LocaleService.tr('urgencyHigh')
            : p.urgency == 'medium'
                ? LocaleService.tr('urgencyMedium')
                : LocaleService.tr('urgencyLow');

        return GestureDetector(
          onTap: () => setState(() {
            if (expanded) {
              _expanded.remove(i);
            } else {
              _expanded.add(i);
            }
          }),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color:
                  isDark ? const Color(0xFF1E1E1E) : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: expanded
                    ? urgencyColor.withOpacity(0.5)
                    : theme.dividerColor.withOpacity(0.2),
                width: expanded ? 1.5 : 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header row ──
                Row(
                  children: [
                    Icon(p.icon, color: p.color, size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        p.symptom,
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: urgencyColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        urgencyLabel,
                        style: TextStyle(
                          fontSize: 10,
                          color: urgencyColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(
                      expanded
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      size: 18,
                      color: theme.textTheme.bodySmall?.color
                          ?.withOpacity(0.35),
                    ),
                  ],
                ),

                // ── Expanded content ──
                if (expanded) ...[
                  const SizedBox(height: 12),
                  Divider(
                      height: 1,
                      color: theme.dividerColor.withOpacity(0.2)),
                  const SizedBox(height: 12),
                  _infoRow(
                    icon: Icons.help_outline,
                    iconColor: Colors.amber,
                    label: LocaleService.tr('assistantCause'),
                    text: p.cause,
                    theme: theme,
                  ),
                  const SizedBox(height: 10),
                  _infoRow(
                    icon: Icons.build,
                    iconColor: Colors.green,
                    label: LocaleService.tr('assistantSolution'),
                    text: p.solution,
                    theme: theme,
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _infoRow({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String text,
    required ThemeData theme,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: iconColor),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color:
                      theme.textTheme.bodySmall?.color?.withOpacity(0.45),
                  fontSize: 10,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(text,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(height: 1.4)),
            ],
          ),
        ),
      ],
    );
  }

  // ── Maintenance tab ─────────────────────────
  Widget _buildMaintTab(ThemeData theme, bool isDark, _Knowledge knowledge) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: knowledge.maint.length,
      itemBuilder: (_, i) {
        final m = knowledge.maint[i];
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: theme.dividerColor.withOpacity(0.2)),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(m.icon,
                    size: 20, color: theme.colorScheme.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(m.name,
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 3),
                    Text(
                      m.interval,
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (m.note.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        m.note,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.textTheme.bodySmall?.color
                              ?.withOpacity(0.5),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Tips tab ────────────────────────────────
  Widget _buildTipsTab(ThemeData theme, bool isDark, _Knowledge knowledge) {
    final extra = identical(knowledge.tips, _tipsGeneral) ||
            knowledge.tips.isEmpty
        ? <_Tip>[]
        : _tipsGeneral;
    final tips = [...knowledge.tips, ...extra];

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: tips.length,
      itemBuilder: (_, i) {
        final t = tips[i];
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: theme.dividerColor.withOpacity(0.2)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(t.icon, size: 20, color: theme.colorScheme.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Text(t.text,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(height: 1.45)),
              ),
            ],
          ),
        );
      },
    );
  }
}
