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

const _tipsAudi = <_Tip>[
  _Tip(icon: Icons.build, text: 'При замене АКБ обязательна кодировка через VAG-COM/ODIS — иначе бортовая электроника не распознаёт новый аккумулятор'),
  _Tip(icon: Icons.opacity, text: 'Меняйте масло каждые 7 500 км — не ждите лампочки Service (интервал занижен для условий СНГ)'),
  _Tip(icon: Icons.sync, text: 'DSG/S-Tronic требует замены масла каждые 40–60 тыс. км — игнорирование ведёт к дорогому ремонту мехатроника'),
  _Tip(icon: Icons.local_fire_department, text: 'Регулярно проверяйте уровень ОЖ — патрубки системы охлаждения склонны к течам после 80 000 км'),
];

const _tipsMazda = <_Tip>[
  _Tip(icon: Icons.opacity, text: 'Двигатели Skyactiv требуют масла 0W-20 или 5W-30 — использование неправильной вязкости повышает расход'),
  _Tip(icon: Icons.rotate_right, text: 'Проверяйте пыльники ШРУСа при каждом ТО — у Mazda 3/6 они склонны к трещинам при низких температурах'),
  _Tip(icon: Icons.sync, text: 'Масло АКПП Skyactiv-Drive меняйте каждые 40–60 тыс. км — производитель говорит «навсегда», реальность иная'),
  _Tip(icon: Icons.local_car_wash, text: 'Покрытие Soul Red Crystal красивое, но требует регулярной полировки с воском — слой лака тоньше среднего'),
];

const _tipsFord = <_Tip>[
  _Tip(icon: Icons.sync, text: 'PowerShift DCT — меняйте масло каждые 40 000 км, иначе рывки при старте станут нормой'),
  _Tip(icon: Icons.opacity, text: 'Двигатели EcoBoost требуют масла 5W-30 с допуском Ford WSS-M2C913 — не заменяйте более дешёвым'),
  _Tip(icon: Icons.rotate_right, text: 'Ступичные подшипники на Focus/Mondeo — слабое место, проверяйте после 60 000 км'),
  _Tip(icon: Icons.battery_charging_full, text: 'На авто с Auto Start/Stop аккумулятор деградирует быстрее — меняйте каждые 4 года'),
];

const _tipsVolvo = <_Tip>[
  _Tip(icon: Icons.opacity, text: 'Меняйте масло строго каждые 10 000 км (или раз в год) — двигатели Drive-E 2.0 чувствительны к качеству масла'),
  _Tip(icon: Icons.settings, text: 'Ремень ГРМ T4/T5 — замена каждые 120 000 км вместе с помпой. Пропуск этой работы = капремонт двигателя'),
  _Tip(icon: Icons.local_car_wash, text: 'Антикоррозийная обработка кузова раз в 2–3 года особенно важна для Volvo в условиях дорог СНГ'),
  _Tip(icon: Icons.ac_unit, text: 'Антибактериальная чистка испарителя кондиционера раз в год — предотвращает запах и защищает систему климата'),
];

const _tipsRenault = <_Tip>[
  _Tip(icon: Icons.sync, text: 'EDC (6DCT) двигателей 1.2 TCe / 1.4 TCe требует замены масла каждые 40 000 км — не откладывайте'),
  _Tip(icon: Icons.opacity, text: 'Дизель K9K требует масла с допуском RN0720 или RN0700 — без совпадения допуска происходит закоксовка'),
  _Tip(icon: Icons.settings, text: 'Ремень ГРМ K9K заменяйте каждые 60 000 км — инструкция «150 000 км» не применима к условиям СНГ'),
  _Tip(icon: Icons.vibration, text: 'Проверяйте опоры двигателя каждые 60 000 км — на Duster/Logan/Kaptur они изнашиваются быстро'),
];

const _tipsSuzuki = <_Tip>[
  _Tip(icon: Icons.opacity, text: 'Меняйте масло каждые 5 000–7 500 км — небольшие атмосферники Suzuki требовательны к чистоте масла'),
  _Tip(icon: Icons.sync, text: 'Масло в CVT меняйте каждые 40 000 км строго оригинальной жидкостью — это продлевает ресурс вариатора'),
  _Tip(icon: Icons.settings, text: 'Ремень ГРМ на Vitara/Grand Vitara меняйте каждые 90 000 км — обрыв гнёт клапаны и ведёт к капремонту'),
  _Tip(icon: Icons.rotate_right, text: 'Смазывайте крестовины карданных валов Jimny каждые 30 000 км — скрип и люфт появляется при недостатке смазки'),
];

const _tipsTesla = <_Tip>[
  _Tip(icon: Icons.battery_charging_full, text: 'Следите за здоровьем батареи — она деградирует 1–2% в год. При <10% обращайтесь в сервис'),
  _Tip(icon: Icons.blur_on, text: 'Минимизируйте быструю зарядку (Supercharger) — 2–3 раза в неделю максимум. Предпочитайте домашнюю зарядку'),
  _Tip(icon: Icons.settings, text: 'Обновления ПО приходят OTA — устанавливайте их сразу же для улучшения производительности и безопасности'),
  _Tip(icon: Icons.ac_unit, text: 'Кондиционер и обогрев — главные враги батареи зимой. Используйте предварительный подогрев от розетки'),
];

const _tipsJaguar = <_Tip>[
  _Tip(icon: Icons.link, text: 'Цепь ГРМ TJ V6 требует замены каждые 120 000 км — обрыв гарантирует капремонт'),
  _Tip(icon: Icons.opacity, text: 'Двигатели Jaguar V6/V8 требуют масла с допуском XJ/XF — не экономьте на оригинале'),
  _Tip(icon: Icons.airline_seat_recline_extra, text: 'Электрическая подвеска (F-Pace) — проверяйте каждые 60 000 км. Компрессор часто отказывает'),
  _Tip(icon: Icons.sync, text: 'АКПП ZF 8HP нуждается в замене масла каждые 60 000 км для стабильной работы'),
];

const _tipsMini = <_Tip>[
  _Tip(icon: Icons.settings, text: 'Ремень ГРМ EA888T менять каждые 90 000 км — MINI склонны к дорогому ремонту при обрыве'),
  _Tip(icon: Icons.opacity, text: 'Масло 5W-30 с допуском BMW LL-04 — используйте только оригинальное, бюджетные аналоги не подойдут'),
  _Tip(icon: Icons.rotate_right, text: 'Проверяйте подшипники ступиц каждые 60 000 км — на MINI они изнашиваются быстрее среднего'),
  _Tip(icon: Icons.ac_unit, text: 'Кондиционер требует регулярной дезинсекции — запах появляется чаще, чем у больших авто'),
];

const _tipsFiat = <_Tip>[
  _Tip(icon: Icons.opacity, text: 'Меняйте масло каждые 7 500 км — двигатели FireFly требовательны к качеству'),
  _Tip(icon: Icons.rotate_right, text: 'Ступичные подшипники Panda/Tipo — проверяйте после 80 000 км, ресурс невелик'),
  _Tip(icon: Icons.settings, text: 'Дроссельная заслонка склонна к закоксовке — чистите каждые 60 000 км профилактически'),
  _Tip(icon: Icons.local_car_wash, text: 'Немедленно обрабатывайте поверхность кузова воском — Fiat подвержены коррозии более других'),
];

const _tipsChery = <_Tip>[
  _Tip(icon: Icons.opacity, text: 'Меняйте масло каждые 5 000 км — недёшево, но необходимо для надёжности'),
  _Tip(icon: Icons.settings, text: 'Требуется регулярная чистка дросселя — двигатели Chery склонны к нагару при городской езде'),
  _Tip(icon: Icons.sync, text: 'КПП можно считать надёжной, но требует адаптации после замены масла через сканер'),
  _Tip(icon: Icons.battery_charging_full, text: 'Диагностика сканером производится редко за пределами China — копите запчасти'),
];

const _tipsVAZ = <_Tip>[
  _Tip(icon: Icons.opacity, text: 'Меняйте масло каждые 5 000–7 500 км — ВАЗ требует частой смены масла в условиях СНГ'),
  _Tip(icon: Icons.local_car_wash, text: 'Защита кузова от коррозии — ГЛАВНАЯ задача. Обработка воском каждые 6 месяцев обязательна'),
  _Tip(icon: Icons.rotate_right, text: 'Проверяйте тормозные диски и колодки каждые 30 000 км — колодки быстро изнашиваются'),
  _Tip(icon: Icons.settings, text: 'Карбюратор требует регулярной регулировки холостого хода (винты качества и количества)'),
];

const _tipsGreatWall = <_Tip>[
  _Tip(icon: Icons.opacity, text: 'Масло 5W-30 менять каждые 5 000–10 000 км в зависимости от стиля езды'),
  _Tip(icon: Icons.settings, text: 'Двигатель требует регулярной чистки форсунок — топливо в СНГ дешёвое низкого качества'),
  _Tip(icon: Icons.sync, text: 'Вариатор (на старых Haval H2/H6) требует замены жидкости каждые 40 000 км оригиналом'),
  _Tip(icon: Icons.rotate_right, text: 'Проверяйте линии охлаждения двигателя каждые 50 000 км — они подвержены течам'),
];

const _tipsGeely = <_Tip>[
  _Tip(icon: Icons.opacity, text: 'Масло каждые 5 000 км оригинальное или Mobil 1 — Geely по качеству лучше Chery/Great Wall'),
  _Tip(icon: Icons.settings, text: 'Дроссельная заслонка требует чистки каждые 60 000 км'),
  _Tip(icon: Icons.battery_charging_full, text: 'На электрических Geely контролируйте состояние батареи — она менее надёжна чем Tesla'),
  _Tip(icon: Icons.vibration, text: 'Звукоизоляция слабая — шум ветра/шин заметен. Это нормально для марки'),
];

const _tipsGenesis = <_Tip>[
  _Tip(icon: Icons.opacity, text: 'Премиум-масло каждые 7 500 км — мотор требует качества'),
  _Tip(icon: Icons.settings, text: 'Электроника продвинутая — требует оригинальной диагностики Hyundai/Genesis'),
  _Tip(icon: Icons.airline_seat_recline_extra, text: 'Пневмоподвеска регулируется по высоте — проверяйте давление каждые 30 000 км'),
  _Tip(icon: Icons.sync, text: 'АКПП 8-ступ на Genesis GV70 требует адаптации после замены масла'),
];

const _tipsXPeng = <_Tip>[
  _Tip(icon: Icons.battery_charging_full, text: 'Батарея — следите за её температурой зимой. Используйте предварительный подогрев'),
  _Tip(icon: Icons.blur_on, text: 'Минимизируйте быструю зарядку — даже для премиального EV она деградирует батарею'),
  _Tip(icon: Icons.settings, text: 'ПО обновляется OTA — устанавливайте обновления сразу, они улучшают управление батареей'),
  _Tip(icon: Icons.ac_unit, text: 'Кондиционер в режиме охлаждения + обогрев салона зимой сильно снижают дальность поездки'),
];

const _tipsNio = <_Tip>[
  _Tip(icon: Icons.battery_charging_full, text: 'NIO использует систему swap батарей — всегда проверяйте состояние новой батареи перед заменой'),
  _Tip(icon: Icons.blur_on, text: 'Дальность зимой падает на 30–40% — планируйте маршруты с запасом'),
  _Tip(icon: Icons.settings, text: 'Сервис в СНГ редок — залог успеха надёжность и профилактика'),
  _Tip(icon: Icons.air, text: 'HEPA фильтры салона меняйте каждые 15 000 км — воздух в авто рекламируется как главное преимущество'),
];

const _tipsCitrogen = <_Tip>[
  _Tip(icon: Icons.opacity, text: 'Масло каждые 7 500 км — двигатели 1.2/1.6 THP требовательны'),
  _Tip(icon: Icons.settings, text: 'Дроссель требует чистки каждые 60 000 км, иначе вибрация на холостом ходу'),
  _Tip(icon: Icons.sync, text: 'Масло EAT6/ EAT8 в АКПП меняйте каждые 60 000 км оригинальным Elf Matic'),
  _Tip(icon: Icons.vibration, text: 'Пневмоподвеска Hydropneumatic на старых C5 — регулируйте давление каждые 6 месяцев'),
];

const _tipsAlfa = <_Tip>[
  _Tip(icon: Icons.opacity, text: 'Масло каждые 7 500 км — итальянские моторы требуют качества и регулярности'),
  _Tip(icon: Icons.settings, text: 'Система зажигания требует профилактики — свечи NGK каждые 30 000 км'),
  _Tip(icon: Icons.rotate_right, text: 'Проверяйте рулевые наконечники каждые 80 000 км — разбалтываются быстро'),
  _Tip(icon: Icons.local_car_wash, text: 'Кузов подвержен коррозии — необходима защита кузова и регулярная мойка, особенно зимой'),
];

const _tipsMG = <_Tip>[
  _Tip(icon: Icons.opacity, text: 'Масло 5W-30 каждые 5 000 км оригинальное — экономия на масле опасна'),
  _Tip(icon: Icons.settings, text: 'Дроссельная заслонка нуждается в чистке каждые 60 000 км'),
  _Tip(icon: Icons.rotate_right, text: 'Подшипники ступиц проверяйте после 80 000 км — слабое звено MG'),
  _Tip(icon: Icons.ac_unit, text: 'Кондиционер требует регулярного обслуживания — запах появляется часто'),
];

const _tipsChangan = <_Tip>[
  _Tip(icon: Icons.opacity, text: 'Масло 5W-30 каждые 5 000 км оригинальное Changan — аналоги не протестированы'),
  _Tip(icon: Icons.settings, text: 'Дроссельная заслонка требует чистки каждые 60 000 км профилактически'),
  _Tip(icon: Icons.rotate_right, text: 'Проверяйте пыльники ШРУСов при каждом ТО — заводское качество оставляет желать лучшего'),
  _Tip(icon: Icons.sync, text: 'МКПП и АКПП требуют адаптации после замены масла через сканер'),
];

const _tipsWuling = <_Tip>[
  _Tip(icon: Icons.opacity, text: 'Масло 5W-30/10W-40 каждые 5 000 км — двигатели Wuling требовательны к качеству'),
  _Tip(icon: Icons.settings, text: 'Требуется регулярная чистка форсунок каждые 40 000 км'),
  _Tip(icon: Icons.vibration, text: 'Проверяйте опоры двигателя каждые 60 000 км — быстро изнашиваются'),
  _Tip(icon: Icons.local_car_wash, text: 'Дёшевое покрытие кузова требует защиты воском каждые 6 месяцев'),
];

const _tipsLiAuto = <_Tip>[
  _Tip(icon: Icons.battery_charging_full, text: 'Батарея Li Auto — контролируйте её здоровье через приложение каждый месяц'),
  _Tip(icon: Icons.blur_on, text: 'Генератор диапазона (EREV система) требует обслуживания каждые 40 000 км'),
  _Tip(icon: Icons.settings, text: 'ПО обновляется OTA — устанавливайте обновления для улучшения управления батареей'),
  _Tip(icon: Icons.ac_unit, text: 'Кондиционер с тепловым секом — используйте эффективно зимой для экономии батареи'),
];

const _tipsAvatar = <_Tip>[
  _Tip(icon: Icons.battery_charging_full, text: 'Батарея CATL — менее надёжна чем Tesla. Следите за её температурой'),
  _Tip(icon: Icons.blur_on, text: 'Быстрая зарядка максимум 2 раза в неделю — батарея деградирует со временем'),
  _Tip(icon: Icons.settings, text: 'Сенсорная панель требует периодической остановки системы для перезагрузки'),
  _Tip(icon: Icons.opacity, text: 'Охлаждающая жидкость батареи требует замены каждые 2 года'),
];

const _tipsNeta = <_Tip>[
  _Tip(icon: Icons.battery_charging_full, text: 'Батарея Neta — экранируйте от жары летом через приложение'),
  _Tip(icon: Icons.blur_on, text: 'Дальность в холод падает на 30–40% — планируйте маршруты с этим фактором'),
  _Tip(icon: Icons.settings, text: 'ПО нуждается в обновлениях для улучшения управления энергией'),
  _Tip(icon: Icons.air, text: 'Воздушный фильтр салона меняйте каждые 20 000 км — фильтр тонкий'),
];

const _tipsLeapmotor = <_Tip>[
  _Tip(icon: Icons.battery_charging_full, text: 'Батарея Leapmotor — избегайте полной разрядки ниже 5%'),
  _Tip(icon: Icons.blur_on, text: 'Минимизируйте быструю зарядку — используйте домашнюю зарядку максимум'),
  _Tip(icon: Icons.settings, text: 'Система охлаждения батареи требует проверки каждые 50 000 км'),
  _Tip(icon: Icons.rotate_right, text: 'Тормозная система регенеративная — изнашивается медленнее, но требует калибровки'),
];

const _tipsPolestar = <_Tip>[
  _Tip(icon: Icons.battery_charging_full, text: 'Батарея Polestar 3/4 — следите за её состоянием. Деградация минимальна, но контроль важен'),
  _Tip(icon: Icons.blur_on, text: 'Быстрая зарядка максимум 2–3 раза в неделю для сохранения ресурса батареи'),
  _Tip(icon: Icons.settings, text: 'ПО обновляется OTA — обновляйте сразу для улучшения управления электроникой'),
  _Tip(icon: Icons.opacity, text: 'На электрических авто контролируйте состояние жидкости охлаждители батареи каждые 2 года'),
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

  // ─── Audi ───
  'audi': _Knowledge(
    about: 'Audi — немецкий премиум с легендарным Quattro AWD. Разделяет платформы с VW/Skoda/Seat. Отличная управляемость, но электроника требует специализированной диагностики.',
    problems: [
      _Problem(
        icon: Icons.sync_problem, color: Color(0xFFF44336),
        symptom: 'Рывки и вибрация DSG/S-Tronic при старте',
        cause: 'Износ фрикционов сухого DQ200 или загрязнение масла мокрого DQ500',
        solution: 'Обновление прошивки мехатроника у дилера. Замена масла DSG (оригинал VW/Audi). При сильном износе — ремонт мехатроника.',
        urgency: 'high',
      ),
      _Problem(
        icon: Icons.link, color: Color(0xFFF44336),
        symptom: 'Стук из ГРМ при холодном пуске (2.0 TFSI)',
        cause: 'Растяжение цепи ГРМ — болячка EA888 Gen1/Gen2',
        solution: 'Замена цепи ГРМ, натяжителя и направляющих. Обязательно при пробеге >120 000 км.',
        urgency: 'high',
      ),
      _Problem(
        icon: Icons.opacity, color: Color(0xFFFF9800),
        symptom: 'Расход масла >0.5 л / 1000 км (2.0 TFSI)',
        cause: 'Закоксовка маслосъёмных колец или износ колпачков',
        solution: 'Промывка двигателя (Liqui Moly Engine Flush). При отсутствии эффекта — снятие ГБЦ и замена колпачков.',
        urgency: 'medium',
      ),
      _Problem(
        icon: Icons.trending_down, color: Color(0xFFFFC107),
        symptom: 'Потеря мощности, свист турбины',
        cause: 'Трещина в патрубке интеркулера или износ актуатора турбины',
        solution: 'Проверить все воздуховоды. При норме — диагностика актуатора турбины через VAG-COM.',
        urgency: 'medium',
      ),
    ],
    maint: _maintGerman,
    tips: _tipsAudi,
  ),

  'audi a4': _Knowledge(
    about: 'Audi A4 (B8/B9) — бизнес-седан с двигателями 1.8/2.0 TFSI. Цепной ГРМ EA888 требует контроля, АКПП S-Tronic — плановой замены масла каждые 60 тыс. км.',
    problems: [
      _Problem(
        icon: Icons.link, color: Color(0xFFF44336),
        symptom: 'Стук при холодном запуске (2.0 TFSI)',
        cause: 'Износ цепи ГРМ — типичная болячка EA888 Gen1/Gen2',
        solution: 'Срочная замена цепного привода ГРМ. Промедление ведёт к капремонту двигателя.',
        urgency: 'high',
      ),
      _Problem(
        icon: Icons.opacity, color: Color(0xFFFF9800),
        symptom: 'Масляный жор >1 л / 10 000 км',
        cause: 'Закоксованные маслосъёмные кольца — ранняя болячка EA888.1',
        solution: 'Промывка колец (Liqui Moly Motorspulung). При отсутствии эффекта — разборка ДВС.',
        urgency: 'medium',
      ),
      _Problem(
        icon: Icons.sync, color: Color(0xFFF44336),
        symptom: 'Рывки и пинки при переключении S-Tronic',
        cause: 'Износ фрикционов 7DCT (DQ200)',
        solution: 'Обновление прошивки мехатроника. При прогрессии — ремонт мехатроника с заменой фрикционов.',
        urgency: 'high',
      ),
    ],
    maint: _maintGerman,
    tips: _tipsAudi,
  ),

  'audi q5': _Knowledge(
    about: 'Audi Q5 (8R/FY) — кроссовер бизнес-класса с полным приводом Quattro. Одна из лучших управляемостей в классе, но требовательный в обслуживании.',
    problems: [
      _Problem(
        icon: Icons.opacity, color: Color(0xFFFF9800),
        symptom: 'Течь масла под авто (2.0 TFSI)',
        cause: 'Износ прокладки клапанной крышки или сальника коленвала',
        solution: 'Замена прокладки клапанной крышки. При сальнике — совмещать с плановым обслуживанием.',
        urgency: 'medium',
      ),
      _Problem(
        icon: Icons.link, color: Color(0xFFF44336),
        symptom: 'Стук ГРМ при запуске (EA888)',
        cause: 'Растяжение цепи ГРМ — актуально для Q5 FY 2017–2021 г.в.',
        solution: 'Замена цепи ГРМ с сопутствующими элементами. Обязательно совмещать с заменой масла.',
        urgency: 'high',
      ),
      _Problem(
        icon: Icons.settings, color: Color(0xFFFFC107),
        symptom: 'Шум при работе полного привода',
        cause: 'Износ муфты Haldex или загрязнение масла',
        solution: 'Замена масла муфты Haldex (ATF Haldex Gen4/5) каждые 40–60 тыс. км. При износе — замена муфты.',
        urgency: 'medium',
      ),
    ],
    maint: _maintGerman,
    tips: _tipsAudi,
  ),

  // ─── Mazda ───
  'mazda': _Knowledge(
    about: 'Mazda — японский бренд с технологией Skyactiv. Атмосферные двигатели с высокой степенью сжатия — мощные и экономичные. Один из лучших в классе по надёжности.',
    problems: [
      _Problem(
        icon: Icons.opacity, color: Color(0xFFFF9800),
        symptom: 'Повышенный расход масла (2.0/2.5 Skyactiv-G)',
        cause: 'Особенность высокой степени сжатия — нагар на кольцах при городской езде',
        solution: 'Промывка двигателя Liqui Moly. Периодически проезжать трассу на 4 000+ об/мин для очистки колец.',
        urgency: 'low',
      ),
      _Problem(
        icon: Icons.rotate_right, color: Color(0xFFFFC107),
        symptom: 'Хруст при повороте руля (Mazda 3/CX-5)',
        cause: 'Износ ШРУСа передней полуоси',
        solution: 'Пыльник цел — набить смазку. При трещинах в пыльнике — немедленная замена ШРУСа.',
        urgency: 'medium',
      ),
      _Problem(
        icon: Icons.vibration, color: Color(0xFFFF9800),
        symptom: 'Небольшие рывки АКПП Skyactiv-Drive',
        cause: 'Загрязнение жидкости АКПП или сброс адаптаций',
        solution: 'Замена жидкости АКПП (ATF-FZ или M-III). Сброс адаптаций через OBD2-диагностику.',
        urgency: 'low',
      ),
    ],
    maint: _maintJapanese,
    tips: _tipsMazda,
  ),

  'mazda cx-5': _Knowledge(
    about: 'Mazda CX-5 (KF) — один из самых популярных кроссоверов класса. Двигатель 2.5 Skyactiv-G надёжен. AWD простой и безотказный. Высший рейтинг безопасности NCAP.',
    problems: [
      _Problem(
        icon: Icons.opacity, color: Color(0xFFFFC107),
        symptom: 'Запотевание оптики фар',
        cause: 'Потеря герметичности корпуса фары (LED/галоген)',
        solution: 'Просушить фару феном. Заклеить вентиляционные отверстия силиконовым герметиком. При сильном — замена.',
        urgency: 'low',
      ),
      _Problem(
        icon: Icons.local_gas_station, color: Color(0xFFFFC107),
        symptom: 'Подёргивания при езде на малых оборотах',
        cause: 'Закоксовка дроссельной заслонки или форсунок',
        solution: 'Чистка дроссельной заслонки. Промывка форсунок. Использовать качественный бензин 95+.',
        urgency: 'low',
      ),
      _Problem(
        icon: Icons.vibration, color: Color(0xFFFF9800),
        symptom: 'Вибрация на скорости 80–120 км/ч',
        cause: 'Дисбаланс колёс или износ ступичных подшипников',
        solution: 'Балансировка и стенд. При пробеге >100 000 км — проверка ступичных подшипников.',
        urgency: 'medium',
      ),
    ],
    maint: _maintJapanese,
    tips: _tipsMazda,
  ),

  'mazda 6': _Knowledge(
    about: 'Mazda 6 (GJ/GL) — спортивный и практичный бизнес-седан/универсал. Двигатели 2.0/2.5 Skyactiv-G надёжны. Шасси настроено остро — лучшее в классе.',
    problems: [
      _Problem(
        icon: Icons.opacity, color: Color(0xFFFFC107),
        symptom: 'Небольшой расход масла',
        cause: 'Особенность высокой степени сжатия Skyactiv-G',
        solution: 'Контролировать уровень каждые 5 000 км. Масло 0W-20. Периодическая езда на трассе очищает кольца.',
        urgency: 'low',
      ),
      _Problem(
        icon: Icons.disc_full, color: Color(0xFFFF9800),
        symptom: 'Вибрация руля при торможении',
        cause: 'Коробление тормозных дисков',
        solution: 'Замена тормозных дисков и колодок. Рекомендуются диски Brembo или DBA.',
        urgency: 'medium',
      ),
    ],
    maint: _maintJapanese,
    tips: _tipsMazda,
  ),

  // ─── Skoda ───
  'skoda': _Knowledge(
    about: 'Skoda — чешский бренд группы VW. Лучшее соотношение цена/качество на платформе MQB. Разделяет двигатели и трансмиссии с VW/Audi/Seat.',
    problems: [
      _Problem(
        icon: Icons.sync_problem, color: Color(0xFFF44336),
        symptom: 'Рывки при старте (1.2/1.4 TSI + DSG7)',
        cause: 'Износ фрикционов сухого DQ200 — болячка всей VW Group',
        solution: 'Обновление прошивки мехатроника у дилера. При сильном износе — ремонт/замена мехатроника.',
        urgency: 'high',
      ),
      _Problem(
        icon: Icons.local_gas_station, color: Color(0xFFFFC107),
        symptom: 'Закоксовка впускных клапанов (1.4 TSI)',
        cause: 'Прямой впрыск не омывает клапаны выхлопными газами',
        solution: 'Чистка клапанов вальцовкой каждые 60–80 тыс. км. Использовать присадки для промывки.',
        urgency: 'medium',
      ),
      _Problem(
        icon: Icons.settings, color: Color(0xFFF44336),
        symptom: 'Стук ГРМ при запуске (1.2 TSI)',
        cause: 'Растяжение цепи ГРМ — критично для моторов CBZA/CBZB до 2014 г.в.',
        solution: 'Замена цепного привода ГРМ. Срочно при пробеге >100 000 км.',
        urgency: 'high',
      ),
    ],
    maint: _maintGerman,
    tips: _tipsGerman,
  ),

  'skoda octavia': _Knowledge(
    about: 'Skoda Octavia (A7/A8) — самый популярный автомобиль Восточной Европы. Практичный лифтбек/универсал с надёжными моторами 1.2/1.4/1.8/2.0 TSI.',
    problems: [
      _Problem(
        icon: Icons.sync, color: Color(0xFFF44336),
        symptom: 'Рывки DSG при трогании в мороз',
        cause: 'Особенность сухого DQ200 в холодную погоду — не прогретые фрикционы',
        solution: 'Прогревать авто 5–10 минут перед движением. При износе — замена масла DSG + адаптация.',
        urgency: 'medium',
      ),
      _Problem(
        icon: Icons.opacity, color: Color(0xFFFFC107),
        symptom: 'Небольшой расход масла 1.4 TSI',
        cause: 'Особенность CZDA/CZEA — маслосъёмные колпачки',
        solution: 'Контролировать уровень масла каждые 3 000 км. При >0.5 л / 1000 км — замена колпачков.',
        urgency: 'medium',
      ),
    ],
    maint: _maintGerman,
    tips: _tipsGerman,
  ),

  // ─── Renault ───
  'renault': _Knowledge(
    about: 'Renault — французский бренд с широкой гаммой. Duster и Logan — популярные бестселлеры СНГ. Простая конструкция Logan позволяет самостоятельный ремонт.',
    problems: [
      _Problem(
        icon: Icons.sync, color: Color(0xFFF44336),
        symptom: 'Рывки/«пинки» роботизированной КПП EDC',
        cause: 'Перегрев или износ фрикционов EDC (6DCT)',
        solution: 'Обновление прошивки EDC. При сильном износе — ремонт мехатроника у специалистов Renault.',
        urgency: 'high',
      ),
      _Problem(
        icon: Icons.settings, color: Color(0xFFF44336),
        symptom: 'Стук ГРМ при запуске (дизель K9K)',
        cause: 'Износ ремня ГРМ — ресурс в СНГ около 60 000 км',
        solution: 'Срочная замена ремня ГРМ с роликами и помпой. Обрыв ремня K9K = капремонт или утиль.',
        urgency: 'high',
      ),
      _Problem(
        icon: Icons.vibration, color: Color(0xFFFF9800),
        symptom: 'Вибрация от подвески (Logan/Duster)',
        cause: 'Износ передних стоек или сайлентблоков рычагов',
        solution: 'Замена передних амортизаторных стоек и опорных подшипников. Доступная и несложная работа.',
        urgency: 'medium',
      ),
      _Problem(
        icon: Icons.ac_unit, color: Color(0xFF2196F3),
        symptom: 'Не работает кондиционер (Duster/Logan)',
        cause: 'Утечка фреона через резиновые уплотнения',
        solution: 'Диагностика кондиционера, дозаправка хладагентом R134a с поиском места утечки.',
        urgency: 'medium',
      ),
    ],
    maint: _maintGeneric,
    tips: _tipsRenault,
  ),

  // ─── Ford ───
  'ford': _Knowledge(
    about: 'Ford — американский бренд с широкой гаммой от Focus до Ranger. Двигатели EcoBoost мощные, но требуют качественного масла и ТО каждые 7 500 км.',
    problems: [
      _Problem(
        icon: Icons.sync, color: Color(0xFFF44336),
        symptom: 'Рывки/«пинки» PowerShift (роботизированная КПП)',
        cause: 'Износ фрикционов или загрязнение масла DPS6 (сухой DCT)',
        solution: 'Замена масла PowerShift. При сильном износе — ремонт/замена мехатроника. Программное обновление.',
        urgency: 'high',
      ),
      _Problem(
        icon: Icons.local_fire_department, color: Color(0xFFF44336),
        symptom: 'Перегрев двигателя 1.0 EcoBoost',
        cause: 'Трещина прокладки ГБЦ — известный дефект 1.0 EcoBoost',
        solution: 'Замена прокладки ГБЦ. Контролировать уровень ОЖ еженедельно и немедленно устранять утечки.',
        urgency: 'high',
      ),
      _Problem(
        icon: Icons.trending_down, color: Color(0xFFFF9800),
        symptom: 'Потеря мощности, свист из-под капота (1.5/1.6T)',
        cause: 'Трещина в патрубке интеркулера или утечка системы наддува',
        solution: 'Проверить патрубки интеркулера на трещины. При норме — диагностика турбокомпрессора.',
        urgency: 'high',
      ),
      _Problem(
        icon: Icons.vibration, color: Color(0xFFFF9800),
        symptom: 'Стук передней подвески (Focus, Mondeo)',
        cause: 'Износ сайлентблоков переднего рычага',
        solution: 'Замена сайлентблоков рычагов передней подвески. Недорогая, но важная работа.',
        urgency: 'medium',
      ),
    ],
    maint: _maintGeneric,
    tips: _tipsFord,
  ),

  // ─── Volvo ───
  'volvo': _Knowledge(
    about: 'Volvo — шведский бренд с приоритетом на безопасность и долговечность. Двигатели Drive-E 2.0 надёжны. Системы безопасности — лучшие в своём классе.',
    problems: [
      _Problem(
        icon: Icons.settings, color: Color(0xFFF44336),
        symptom: 'Стук ремня ГРМ (T4/T5, Drive-E 2.0)',
        cause: 'Износ натяжного ролика или самого ремня ГРМ',
        solution: 'Замена ремня ГРМ с роликами и помпой каждые 120 000 км. Обрыв = капремонт двигателя.',
        urgency: 'high',
      ),
      _Problem(
        icon: Icons.airline_seat_recline_extra, color: Color(0xFFFF9800),
        symptom: 'Подвеска «опускается» на стоянке',
        cause: 'Износ пневмостоек или компрессора (XC90 II, XC60)',
        solution: 'Замена пневмостоек (Continental или оригинал Volvo). Диагностика компрессора подвески.',
        urgency: 'high',
      ),
      _Problem(
        icon: Icons.opacity, color: Color(0xFFFFC107),
        symptom: 'Подтёк масла в районе двигателя',
        cause: 'Прокладка масляного поддона или сальник коленвала (Drive-E)',
        solution: 'Замена прокладок по месту течи. Силиконовый герметик не заменяет прокладку.',
        urgency: 'medium',
      ),
    ],
    maint: _maintGerman,
    tips: _tipsVolvo,
  ),

  // ─── Land Rover ───
  'land rover': _Knowledge(
    about: 'Land Rover — британский бренд с легендарными внедорожными качествами. Discovery, Defender, Range Rover — одни из лучших вездеходов. Высокая стоимость обслуживания.',
    problems: [
      _Problem(
        icon: Icons.airline_seat_recline_extra, color: Color(0xFFF44336),
        symptom: 'Автомобиль оседает после стоянки',
        cause: 'Износ пневмостоек или компрессора подвески (Range Rover)',
        solution: 'Замена пневмостоек (Arnott или оригинал) и/или компрессора. Конвертация на пружины — бюджетный вариант.',
        urgency: 'high',
      ),
      _Problem(
        icon: Icons.local_fire_department, color: Color(0xFFF44336),
        symptom: 'Перегрев дизеля 3.0 TDV6/SDV6',
        cause: 'Засорение системы охлаждения или износ водяной помпы',
        solution: 'Замена помпы, термостата и промывка системы охлаждения. Профилактически каждые 80 000 км.',
        urgency: 'high',
      ),
      _Problem(
        icon: Icons.settings, color: Color(0xFFFF9800),
        symptom: 'Пинки/зависания АКПП ZF 8HP',
        cause: 'Загрязнение масла АКПП или износ гидроблока',
        solution: 'Замена масла АКПП (ZF Lifeguard 8) каждые 60 000 км. При прогрессии — диагностика гидроблока.',
        urgency: 'medium',
      ),
    ],
    maint: _maintGerman,
    tips: _tipsGerman,
  ),

  // ─── Porsche ───
  'porsche': _Knowledge(
    about: 'Porsche — немецкий спортивный бренд. Невероятная надёжность при правильном обслуживании. Cayenne и Macan на платформе Audi — надёжны как японцы.',
    problems: [
      _Problem(
        icon: Icons.settings, color: Color(0xFFFF9800),
        symptom: 'Стук подвески (Cayenne/Macan) на кочках',
        cause: 'Износ сайлентблоков рычагов задней многорычажки',
        solution: 'Замена сайлентблоков задней многорычажной подвески. Рекомендуется усиленный комплект MEYLE HD.',
        urgency: 'medium',
      ),
      _Problem(
        icon: Icons.sync, color: Color(0xFFFFC107),
        symptom: 'Вибрация/рывки PDK при старте',
        cause: 'Загрязнение масла PDK или необходимость адаптации',
        solution: 'Замена масла PDK оригинальным Porsche PDK Fluid каждые 40 000 км. Адаптация через Porsche PIWIS.',
        urgency: 'medium',
      ),
      _Problem(
        icon: Icons.opacity, color: Color(0xFFF44336),
        symptom: 'Расход масла (V6/V8 бензиновые моторы)',
        cause: 'Характерная особенность спортивных двигателей — нагружены сильнее обычного',
        solution: 'Контролировать уровень каждые 2 000 км. 0.5 л / 1000 км считается условно нормальным.',
        urgency: 'low',
      ),
    ],
    maint: _maintGerman,
    tips: _tipsGerman,
  ),

  // ─── Jeep ───
  'jeep': _Knowledge(
    about: 'Jeep — американский внедорожный бренд (Stellantis). Grand Cherokee и Wrangler — культовые внедорожники. Простая конструкция, но требует регулярного ТО.',
    problems: [
      _Problem(
        icon: Icons.airline_seat_recline_extra, color: Color(0xFFFF9800),
        symptom: 'Оседает пневмоподвеска (Grand Cherokee)',
        cause: 'Износ пневмостоек или компрессора',
        solution: 'Замена пневмостоек (Arnott или оригинал). Диагностика компрессора и осушителя.',
        urgency: 'high',
      ),
      _Problem(
        icon: Icons.settings, color: Color(0xFFF44336),
        symptom: 'Скрежет/гул раздаточной коробки',
        cause: 'Износ подшипников или нехватка масла в раздатке',
        solution: 'Замена масла раздатки каждые 60 000 км. При скрежете — диагностика подшипников.',
        urgency: 'high',
      ),
      _Problem(
        icon: Icons.local_gas_station, color: Color(0xFFFFC107),
        symptom: 'Повышенный расход топлива (3.6 Pentastar)',
        cause: 'Загрязнение инжекторов или проблема клапана деактивации MDS',
        solution: 'Промывка инжекторов. Проверка работы системы MDS (отключение цилиндров).',
        urgency: 'low',
      ),
    ],
    maint: _maintGeneric,
    tips: _tipsGeneral,
  ),

  // ─── Suzuki ───
  'suzuki': _Knowledge(
    about: 'Suzuki — японский бренд компактных и внедорожных автомобилей. Vitara и Swift — надёжные и экономичные. AllGrip AWD отлично работает в условиях СНГ.',
    problems: [
      _Problem(
        icon: Icons.sync, color: Color(0xFFFFC107),
        symptom: 'Рывки вариатора CVT (Vitara, Swift)',
        cause: 'Загрязнение жидкости CVT или начальный износ ремня',
        solution: 'Замена жидкости CVT строго оригинальной Suzuki CVT Fluid Green 1 каждые 40 000 км.',
        urgency: 'medium',
      ),
      _Problem(
        icon: Icons.settings, color: Color(0xFFF44336),
        symptom: 'Стук ремня ГРМ (Grand Vitara, Jimny)',
        cause: 'Износ ролика или самого ремня ГРМ — ресурс 90 000 км',
        solution: 'Замена ремня ГРМ с роликами и помпой. Обрыв гнёт клапаны — работа обязательна.',
        urgency: 'high',
      ),
      _Problem(
        icon: Icons.rotate_right, color: Color(0xFFFF9800),
        symptom: 'Люфт и скрип карданных валов (Jimny)',
        cause: 'Износ крестовин или недостаток смазки',
        solution: 'Смазка крестовин или их замена. Профилактическая смазка каждые 30 000 км.',
        urgency: 'medium',
      ),
    ],
    maint: _maintJapanese,
    tips: _tipsSuzuki,
  ),

  // ─── Opel ───
  'opel': _Knowledge(
    about: 'Opel (Stellantis) — немецкий бренд с доступным обслуживанием. Astra и Insignia — популярны в СНГ. Двигатели 1.4/1.6 Turbo надёжны при соблюдении ТО.',
    problems: [
      _Problem(
        icon: Icons.link, color: Color(0xFFF44336),
        symptom: 'Стук цепи ГРМ при запуске (1.6 Turbo A16LET)',
        cause: 'Растяжение цепи ГРМ — болячка 1.6T первых поколений',
        solution: 'Замена цепного привода ГРМ. Профилактически при пробеге >100 000 км.',
        urgency: 'high',
      ),
      _Problem(
        icon: Icons.vibration, color: Color(0xFFFF9800),
        symptom: 'Стук передней подвески (Astra/Insignia)',
        cause: 'Износ опорного подшипника стойки или сайлентблоков рычагов',
        solution: 'Замена опорных подшипников + сайлентблоков передних рычагов.',
        urgency: 'medium',
      ),
      _Problem(
        icon: Icons.opacity, color: Color(0xFFFFC107),
        symptom: 'Течь масла двигателя',
        cause: 'Износ сальника коленвала или прокладки клапанной крышки',
        solution: 'Замена сальников по месту течи + прокладки клапанной крышки. Доступные запчасти.',
        urgency: 'medium',
      ),
    ],
    maint: _maintGerman,
    tips: _tipsGerman,
  ),

  // ─── Peugeot ───
  'peugeot': _Knowledge(
    about: 'Peugeot (Stellantis) — французский бренд с динамичным дизайном. Двигатель 1.6 THP создан совместно с BMW. 2008, 3008 — успешные кроссоверы своего класса.',
    problems: [
      _Problem(
        icon: Icons.link, color: Color(0xFFF44336),
        symptom: 'Стук цепи ГРМ (1.6 THP EP6)',
        cause: 'Растяжение цепи ГРМ — известная проблема мотора Prince (совместный с BMW Mini)',
        solution: 'Замена цепного привода ГРМ. Критично! Промедление = капремонт.',
        urgency: 'high',
      ),
      _Problem(
        icon: Icons.opacity, color: Color(0xFFFF9800),
        symptom: 'Расход масла (1.6 THP)',
        cause: 'Закоксовка маслосъёмных колец или износ колпачков',
        solution: 'Следить за уровнем масла каждые 2 000–3 000 км. Промывка, при отсутствии эффекта — ремонт ГБЦ.',
        urgency: 'medium',
      ),
      _Problem(
        icon: Icons.settings, color: Color(0xFFFFC107),
        symptom: 'Рывки роботизированной КПП EGS',
        cause: 'Износ привода или необходимость обучить точку сцепления',
        solution: 'Адаптация точки сцепления через диагностику. При износе — замена диска сцепления.',
        urgency: 'medium',
      ),
    ],
    maint: _maintGeneric,
    tips: _tipsRenault,
  ),

  // ─── Infiniti ───
  'infiniti': _Knowledge(
    about: 'Infiniti — премиальный бренд Nissan. Двигатели VQ35/VQ37 — одни из лучших V6 в мире по надёжности. FX, QX60, Q50 популярны в премиум-сегменте СНГ.',
    problems: [
      _Problem(
        icon: Icons.opacity, color: Color(0xFFFFC107),
        symptom: 'Небольшой масляный жор (VQ35)',
        cause: 'Особенность двигателя VQ35DE — небольшой расход считается нормальным',
        solution: 'Контролировать уровень каждые 5 000 км. 0.5 л / 5000 км — норма. При >1 л — диагностика.',
        urgency: 'low',
      ),
      _Problem(
        icon: Icons.sync, color: Color(0xFFF44336),
        symptom: 'Вибрация вариатора Xtronic (QX60/Q50)',
        cause: 'Загрязнение жидкости CVT Jatco',
        solution: 'Замена жидкости CVT оригинальной NS-3 каждые 30 000 км. Только оригинал.',
        urgency: 'high',
      ),
      _Problem(
        icon: Icons.vibration, color: Color(0xFFFF9800),
        symptom: 'Стук задней подвески (FX35/QX70)',
        cause: 'Износ задних рычагов или стоек стабилизатора',
        solution: 'Замена стоек стабилизатора + задних сайлентблоков. Распространённая работа.',
        urgency: 'medium',
      ),
    ],
    maint: _maintJapanese,
    tips: _tipsToyota,
  ),

  // ─── UAZ ───
  'uaz': _Knowledge(
    about: 'УАЗ — ульяновский внедорожник почти армейской конструкции. Простота обслуживания и высокая ремонтопригодность — главные достоинства. Проходимость — вне конкуренции.',
    problems: [
      _Problem(
        icon: Icons.opacity, color: Color(0xFFFFC107),
        symptom: 'Течь масла из двигателя',
        cause: 'Большие допуски производства — у старых экземпляров уплотнения дают течь',
        solution: 'Планомерная замена всех сальников и прокладок. Недорогие запчасти — самостоятельный ремонт вполне возможен.',
        urgency: 'medium',
      ),
      _Problem(
        icon: Icons.rotate_right, color: Color(0xFFFF9800),
        symptom: 'Люфт рулевого управления',
        cause: 'Износ рулевой трапеции или рулевого вала',
        solution: 'Регулировка рулевого червяка. Замена рулевых наконечников. Обязательная сход-развал.',
        urgency: 'medium',
      ),
      _Problem(
        icon: Icons.settings, color: Color(0xFF9E9E9E),
        symptom: 'Скрежет/гул раздаточной коробки',
        cause: 'Износ подшипников или нехватка масла',
        solution: 'Замена масла раздатки. Ревизия подшипников. Б/у запчасти доступны на любом рынке.',
        urgency: 'medium',
      ),
    ],
    maint: _maintGeneric,
    tips: _tipsGeneral,
  ),

  // ─── BMW X5 ───
  'bmw x5': _Knowledge(
    about: 'BMW X5 (E70/F15/G05) — флагманский кроссовер BMW. Мощные бензиновые и дизельные моторы. xDrive AWD — превосходен на зимней дороге. Дорог в обслуживании.',
    problems: [
      _Problem(
        icon: Icons.local_fire_department, color: Color(0xFFF44336),
        symptom: 'Течь ОЖ / перегрев (N63 4.4T biturbo)',
        cause: 'Растрескивание пластиковых патрубков — известная болячка N63',
        solution: 'Замена всех патрубков системы охлаждения. Профилактически при пробеге >80 000 км.',
        urgency: 'high',
      ),
      _Problem(
        icon: Icons.link, color: Color(0xFFF44336),
        symptom: 'Характерный стук ГРМ при запуске',
        cause: 'Растяжение двойной цепи ГРМ N63/N55/N57',
        solution: 'Замена цепей ГРМ — дорогостоящая работа, но обязательная при пробеге >100 000 км.',
        urgency: 'high',
      ),
      _Problem(
        icon: Icons.airline_seat_recline_extra, color: Color(0xFFFF9800),
        symptom: 'Машина оседает после ночной стоянки',
        cause: 'Износ пневмобаллонов или компрессора (опционная пневмоподвеска F15)',
        solution: 'Замена пневмостоек или конвертация на стандартные пружины. Компрессор менять отдельно.',
        urgency: 'high',
      ),
    ],
    maint: _maintGerman,
    tips: _tipsGerman,
  ),

  // ─── BMW 3 series ───
  'bmw 3': _Knowledge(
    about: 'BMW 3 серии (F30/G20) — эталон бизнес-седана. Двигатели B48/N20 2.0T с надёжной цепью. Задний привод с отличными ходовыми качествами. Дороговат в обслуживании.',
    problems: [
      _Problem(
        icon: Icons.link, color: Color(0xFFFF9800),
        symptom: 'Стук при запуске (N20 2.0T, F30)',
        cause: 'Растяжение цепи ГРМ N20 — в отличие от B48, N20 склонен к растяжению',
        solution: 'Замена цепи ГРМ. Профилактически при пробеге >100 000 км на N20.',
        urgency: 'high',
      ),
      _Problem(
        icon: Icons.local_fire_department, color: Color(0xFFFFC107),
        symptom: 'Течь ОЖ / запах антифриза',
        cause: 'Растрескивание пластиковых соединений расширительного бачка',
        solution: 'Замена расширительного бачка и патрубков СО. Профилактически при пробеге >80 000 км.',
        urgency: 'high',
      ),
      _Problem(
        icon: Icons.opacity, color: Color(0xFFFFC107),
        symptom: 'Небольшой расход масла',
        cause: 'Особенность турбированных BMW — небольшое потребление масла турбиной',
        solution: 'Контролировать уровень каждые 3 000 км. До 0.5 л / 5000 км — норма.',
        urgency: 'low',
      ),
    ],
    maint: _maintGerman,
    tips: _tipsGerman,
  ),

  // ─── Kia Sportage ───
  'kia sportage': _Knowledge(
    about: 'Kia Sportage (QL/NQ5) — один из самых продаваемых кроссоверов СНГ. Двигатели G4FJ 1.6T и Smartstream 2.0 современные. АКПП 6AT надёжнее 7DCT для города.',
    problems: [
      _Problem(
        icon: Icons.sync, color: Color(0xFFF44336),
        symptom: 'Рывки 7DCT при старте (1.6 Turbo)',
        cause: 'Особенность сухого 7DCT в городском режиме — перегрев фрикционов',
        solution: 'Обновление прошивки мехатроника у дилера. При износе — замена масла DCT + адаптация.',
        urgency: 'high',
      ),
      _Problem(
        icon: Icons.ac_unit, color: Color(0xFF2196F3),
        symptom: 'Запах при включении кондиционера',
        cause: 'Бактерии и плесень на испарителе',
        solution: 'Антибактериальная обработка испарителя + замена фильтра салона. Ежегодно.',
        urgency: 'low',
      ),
      _Problem(
        icon: Icons.rotate_right, color: Color(0xFFFF9800),
        symptom: 'Стук рулевого управления на кочках',
        cause: 'Износ наконечников рулевых тяг или рулевой рейки',
        solution: 'Замена рулевых наконечников. При прогрессии — диагностика электрорулевой рейки.',
        urgency: 'medium',
      ),
    ],
    maint: _maintKorean,
    tips: _tipsKorean,
  ),

  // ─── Hyundai Tucson ───
  'hyundai tucson': _Knowledge(
    about: 'Hyundai Tucson (TL/NX4) — современный кроссовер с широкой гаммой моторов. 2.0 MPI надёжнее 1.6 T-GDI. AWD HTRAC обеспечивает хорошую управляемость.',
    problems: [
      _Problem(
        icon: Icons.sync, color: Color(0xFFF44336),
        symptom: 'Рывки при старте (1.6 T-GDI + 7DCT)',
        cause: 'Особенность сухого 7DCT — перегрев фрикционов в городских пробках',
        solution: 'Eco-режим в пробках снижает нагрузку. Обновление прошивки DCT у дилера.',
        urgency: 'medium',
      ),
      _Problem(
        icon: Icons.opacity, color: Color(0xFFFF9800),
        symptom: 'Небольшой расход масла (1.6 T-GDI)',
        cause: 'Особенность прямовпрысковых турбодвигателей',
        solution: 'Контролировать уровень каждые 3 000 км. Масло 0W-30 ACEA C3.',
        urgency: 'low',
      ),
      _Problem(
        icon: Icons.vibration, color: Color(0xFFFF9800),
        symptom: 'Вибрация на скорости',
        cause: 'Дисбаланс шин или износ ступичных подшипников',
        solution: 'Балансировка + стенд. При пробеге >80 000 км — замена ступичных подшипников.',
        urgency: 'medium',
      ),
    ],
    maint: _maintKorean,
    tips: _tipsKorean,
  ),

  // ─── Toyota Corolla ───
  'toyota corolla': _Knowledge(
    about: 'Toyota Corolla (E210) — самый продаваемый автомобиль в истории. Двигатели 1.6/2.0 Valvematic надёжны. Минимальные затраты на обслуживание в классе.',
    problems: [
      _Problem(
        icon: Icons.opacity, color: Color(0xFFFFC107),
        symptom: 'Небольшой масляный аппетит (2.0 M20A)',
        cause: 'Характерная особенность ранних M20A — расход до 0.5 л/5000 км',
        solution: 'Контролировать уровень каждые 3 000 км. Масло 0W-20 с допуском Toyota.',
        urgency: 'low',
      ),
      _Problem(
        icon: Icons.vibration, color: Color(0xFFFF9800),
        symptom: 'Вибрация на холостом ходу',
        cause: 'Загрязнение дроссельной заслонки или нагар на форсунках',
        solution: 'Чистка дроссельной заслонки. Промывка форсунок. Замена свечей NGK (оригинал).',
        urgency: 'low',
      ),
      _Problem(
        icon: Icons.disc_full, color: Color(0xFFFF9800),
        symptom: 'Вибрация руля при торможении',
        cause: 'Коробление тормозных дисков — особенность ранних 2019–2021 г.в.',
        solution: 'Замена тормозных дисков (TRD или SHW) + колодок. Проточка дисков не рекомендуется.',
        urgency: 'medium',
      ),
    ],
    maint: _maintJapanese,
    tips: _tipsToyota,
  ),

  // ─── Toyota Highlander ───
  'toyota highlander': _Knowledge(
    about: 'Toyota Highlander (XU50/XU70) — семейный кроссовер с 3-рядами сидений. Двигатели 3.5 V6 / 2.5 Hybrid. AWD Torsen — отличный для трассы и снега.',
    problems: [
      _Problem(
        icon: Icons.settings, color: Color(0xFFFFC107),
        symptom: 'Вибрация при работе АКПП (2GR-FKS)',
        cause: 'Загрязнение жидкости АКПП или нагар на дроссельной заслонке',
        solution: 'Замена жидкости АКПП Toyota ATF WS. Чистка дроссельной заслонки.',
        urgency: 'low',
      ),
      _Problem(
        icon: Icons.battery_charging_full, color: Color(0xFFFF9800),
        symptom: 'Деградация гибридной батареи (Hybrid версия)',
        cause: 'Постепенный износ NiMH/Li-ion ячеек после 150 000+ км',
        solution: 'Восстановление или замена гибридного аккумулятора у специалистов по гибридам Toyota.',
        urgency: 'medium',
      ),
    ],
    maint: _maintJapanese,
    tips: _tipsToyota,
  ),

  // ─── VW Golf ───
  'volkswagen golf': _Knowledge(
    about: 'VW Golf (7/8 поколение) — эталон гольф-класса. Двигатели EA888 1.8/2.0 TSI + DSG. Надёжен при правильном обслуживании. Высокая ценность на вторичном рынке.',
    problems: [
      _Problem(
        icon: Icons.sync, color: Color(0xFFF44336),
        symptom: 'Рывки DSG7 (DQ200) при старте',
        cause: 'Типичная болячка вся VW Group — износ фрикционов сухого DSG7',
        solution: 'Обновление прошивки мехатроника. При износе — ремонт мехатроника + замена масла DSG.',
        urgency: 'high',
      ),
      _Problem(
        icon: Icons.local_gas_station, color: Color(0xFFFFC107),
        symptom: 'Закоксовка клапанов (2.0 TSI EA888)',
        cause: 'Прямой впрыск не омывает впускные клапаны',
        solution: 'Чистка впускных клапанов вальцовкой или промывкой каждые 60–80 тыс. км.',
        urgency: 'medium',
      ),
      _Problem(
        icon: Icons.settings, color: Color(0xFFFF9800),
        symptom: 'Расход масла 2.0 TSI',
        cause: 'Закоксовка маслосъёмных колец — ранняя болячка EA888',
        solution: 'Промывка колец (Liqui Moly). При отсутствии эффекта — замена колец/колпачков.',
        urgency: 'medium',
      ),
    ],
    maint: _maintGerman,
    tips: _tipsGerman,
  ),

  // ─── Mercedes C-Class ───
  'mercedes c': _Knowledge(
    about: 'Mercedes C-Class (W205/W206) — бизнес-седан с богатым оснащением. Двигатели OM651 (2.2 CDI) и M274 (2.0T) надёжны. Сложная электроника требует специализированной диагностики.',
    problems: [
      _Problem(
        icon: Icons.link, color: Color(0xFFF44336),
        symptom: 'Стук при запуске дизеля OM651',
        cause: 'Износ цепи ГРМ или натяжителя — известный дефект OM651 до 2014 г.в.',
        solution: 'Замена цепного привода ГРМ — срочно. OM651 известен этой проблемой на ранних версиях.',
        urgency: 'high',
      ),
      _Problem(
        icon: Icons.opacity, color: Color(0xFFFF9800),
        symptom: 'Течь масла (M274 2.0 Turbo)',
        cause: 'Износ прокладки клапанной крышки',
        solution: 'Замена прокладки клапанной крышки. Доступная работа.',
        urgency: 'medium',
      ),
      _Problem(
        icon: Icons.vibration, color: Color(0xFFFFC107),
        symptom: 'Скрипы из задней подвески (W205)',
        cause: 'Износ сайлентблоков рычагов задней многорычажки',
        solution: 'Замена сайлентблоков задних рычагов (MEYLE HD или оригинал). Необходима сход-развал.',
        urgency: 'medium',
      ),
    ],
    maint: _maintGerman,
    tips: _tipsGerman,
  ),

  // ─── Mercedes GLE ───
  'mercedes gle': _Knowledge(
    about: 'Mercedes GLE (W166/V167) — полноразмерный SUV с богатым оснащением и пневмоподвеской. Мощные двигатели дизель/бензин. Один из самых комфортных кроссоверов класса.',
    problems: [
      _Problem(
        icon: Icons.airline_seat_recline_extra, color: Color(0xFFF44336),
        symptom: 'Автомобиль оседает на одну сторону',
        cause: 'Износ пневмобаллона или клапана Airmatic',
        solution: 'Замена пневмостоек (оригинал или Continental). Диагностика компрессора Airmatic.',
        urgency: 'high',
      ),
      _Problem(
        icon: Icons.sync, color: Color(0xFFFF9800),
        symptom: 'Толчки АКПП 7G-Tronic при переключении',
        cause: 'Загрязнение масла АКПП или износ гидроблока',
        solution: 'Замена масла 7G-Tronic (Shell M1375.4 или оригинал) каждые 60 000 км.',
        urgency: 'medium',
      ),
    ],
    maint: _maintGerman,
    tips: _tipsGerman,
  ),

  // ─── Kia Rio ───
  'kia rio': _Knowledge(
    about: 'Kia Rio (FB/YB) — самый доступный и популярный К-car в СНГ. Двигатель G4FC 1.6 DOHC прост и надёжен. Механическая КПП надёжнее автомата на этой машине.',
    problems: [
      _Problem(
        icon: Icons.vibration, color: Color(0xFFFF9800),
        symptom: 'Вибрация на малых оборотах',
        cause: 'Загрязнение дроссельной заслонки или засорение форсунок',
        solution: 'Чистка дросселя снятием. Замена свечей. Промывка форсунок присадкой в бак.',
        urgency: 'low',
      ),
      _Problem(
        icon: Icons.album, color: Color(0xFFFF9800),
        symptom: 'Скрип тормозов',
        cause: 'Износ тормозных колодок или окисление тормозных направляющих',
        solution: 'Замена колодок. Смазка направляющих (медная смазка, не на рабочую поверхность).',
        urgency: 'medium',
      ),
      _Problem(
        icon: Icons.settings, color: Color(0xFFFFC107),
        symptom: 'Стук ремня ГРМ (высокопробежные G4FC)',
        cause: 'Износ ремня или ролика на пробеге >90 000 км',
        solution: 'Замена ремня ГРМ с роликами и помпой. Обязательно каждые 90 000 км.',
        urgency: 'high',
      ),
    ],
    maint: _maintKorean,
    tips: _tipsKorean,
  ),

  // ─── MINI ───
  'mini': _Knowledge(
    about: 'MINI (BMW) — городской хетчбек с энергичным характером. Двигатель EA888T надёжен. Высокая стоимость запчастей как у BMW, но размеры авто компактны.',
    problems: [
      _Problem(
        icon: Icons.settings, color: Color(0xFFF44336),
        symptom: 'Стук цепи ГРМ из двигателя',
        cause: 'Растяжение цепи EA888T — критично на пробеге >100 000 км',
        solution: 'Замена цепного привода ГРМ. Огромная стоимость работы и запчастей даже для компактного MINI.',
        urgency: 'high',
      ),
      _Problem(
        icon: Icons.opacity, color: Color(0xFFFF9800),
        symptom: 'Течь масла из ГБЦ',
        cause: 'Износ прокладки клапанной крышки',
        solution: 'Замена прокладки. Доступна замена.',
        urgency: 'medium',
      ),
      _Problem(
        icon: Icons.rotate_right, color: Color(0xFFFF9800),
        symptom: 'Люфт в рулевом управлении',
        cause: 'Износ рулевых наконечников и втулок',
        solution: 'Замена рулевых наконечников. Обязательна сход-развал.',
        urgency: 'medium',
      ),
    ],
    maint: _maintGerman,
    tips: _tipsMini,
  ),

  // ─── Tesla ───
  'tesla': _Knowledge(
    about: 'Tesla — лидер электромобилей с уникальным ПО и батареей. Model 3/Y — бестселлеры EV. Зарядка от домашней розетки, минимальное ТО, рекуперативное торможение.',
    problems: [
      _Problem(
        icon: Icons.battery_charging_full, color: Color(0xFFF44336),
        symptom: 'Батарея деградирует быстро / снижается дальность',
        cause: 'Частая быстрая зарядка, экстремальные температуры',
        solution: 'Используйте домашнюю зарядку 80% и минимизируйте Supercharger. Избегайте минус температур без прогрева.',
        urgency: 'high',
      ),
      _Problem(
        icon: Icons.blur_on, color: Color(0xFFFF9800),
        symptom: 'Дальность упала на 10–15% в морозе',
        cause: 'Батарея теряет мощность при низких температурах — нормально для LiPo',
        solution: 'Используйте предварительный подогрев от розетки перед выездом. Избегайте агрессивного вождения.',
        urgency: 'low',
      ),
      _Problem(
        icon: Icons.settings, color: Color(0xFFFFC107),
        symptom: 'Нестабильная работа Автопилота / Супер Крузер',
        cause: 'Загрязнение камер или необходимо обновление ПО',
        solution: 'Обновите ПО сразу (приходит OTA). Очистите камеры от пыли/грязи.',
        urgency: 'low',
      ),
      _Problem(
        icon: Icons.vibration, color: Color(0xFFFFC107),
        symptom: 'Вибрация на высоких скоростях (>150 км/ч)',
        cause: 'Дисбаланс колёс или износ подшипников',
        solution: 'Балансировка колёс и проверка подшипников. На Tesla редко требуется замена подшипников.',
        urgency: 'low',
      ),
    ],
    maint: _maintGeneric,
    tips: _tipsTesla,
  ),

  'tesla model 3': _Knowledge(
    about: 'Tesla Model 3 — самый продаваемый электрокар в мире. Две батареи: Standard/Long Range. Электромотор проще любого ДВС — почти вечный мотор при своевременной зарядке.',
    problems: [
      _Problem(
        icon: Icons.battery_charging_full, color: Color(0xFFF44336),
        symptom: 'Быстрая деградация батареи первых лет',
        cause: 'Производственный брак или частая DC зарядка при покупке',
        solution: 'Проверить батарею диагностикой. Tesla часто заменяет батарею по гарантии на ранних версиях.',
        urgency: 'high',
      ),
      _Problem(
        icon: Icons.disc_full, color: Color(0xFFFF9800),
        symptom: 'Передние тормозные колодки ношены, задние идеальны',
        cause: 'Рекуперативное торможение — задние тормоза почти не используются',
        solution: 'Нормально для EV. Передние тормозные колодки менять реже, чем на ДВС авто.',
        urgency: 'low',
      ),
      _Problem(
        icon: Icons.rotate_right, color: Color(0xFFFF9800),
        symptom: 'Странные звуки из подвески на скорости',
        cause: 'Люфт в рулевых тягах или амортизаторах',
        solution: 'Диагностика подвески. На Model 3 обычно достаточно регулировки.',
        urgency: 'medium',
      ),
    ],
    maint: _maintGeneric,
    tips: _tipsTesla,
  ),

  // ─── Fiat ───
  'fiat': _Knowledge(
    about: 'Fiat — итальянский бренд с простыми, дешёвыми авто. Panda, Tipo, 500 — легенды роллинга. Компактные, экономичные, восприимчивы к коррозии.',
    problems: [
      _Problem(
        icon: Icons.opacity, color: Color(0xFFFFC107),
        symptom: 'Вибрация на холостом ходу (1.2/1.4)',
        cause: 'Загрязнение дроссельной заслонки',
        solution: 'Чистка дроссельной заслонки. Простая и дешёвая работа.',
        urgency: 'low',
      ),
      _Problem(
        icon: Icons.local_car_wash, color: Color(0xFFF44336),
        symptom: 'Коррозия кузова даже на молодых авто',
        cause: 'Fiat известны слабой защитой кузова от ржавчины',
        solution: 'Обработка кузова воском каждые 6 месяцев. Немедленный ремонт царапин.',
        urgency: 'high',
      ),
      _Problem(
        icon: Icons.rotate_right, color: Color(0xFFFF9800),
        symptom: 'Люфт рулевого управления',
        cause: 'Износ втулок рулевых тяг',
        solution: 'Замена рулевых наконечников и втулок. Недорого.',
        urgency: 'medium',
      ),
    ],
    maint: _maintGeneric,
    tips: _tipsFiat,
  ),

  'fiat panda': _Knowledge(
    about: 'Fiat Panda (169/290/312) — легендарная малютка. Простота конструкции позволяет самостоятельный ремонт на парковке. Два литра на 100 км реально достижимы.',
    problems: [
      _Problem(
        icon: Icons.opacity, color: Color(0xFFFFC107),
        symptom: 'Слабая мощность двигателя',
        cause: 'Засорение воздушного фильтра или форсунок (1.2i 8V)',
        solution: 'Замена фильтра, промывка форсунок, сброс ошибок ЭБУ.',
        urgency: 'low',
      ),
      _Problem(
        icon: Icons.vibration, color: Color(0xFFFF9800),
        symptom: 'Вибрация на малых оборотах',
        cause: 'Изношены подушки двигателя',
        solution: 'Замена подушек. Недорогие, доступные детали.',
        urgency: 'low',
      ),
    ],
    maint: _maintGeneric,
    tips: _tipsFiat,
  ),

  // ─── Alfa Romeo ───
  'alfa romeo': _Knowledge(
    about: 'Alfa Romeo — итальянский премиум-бренд с душой спортсмена. Giulia, Stelvio — роскошные авто с динамичным характером. Требует качественного обслуживания.',
    problems: [
      _Problem(
        icon: Icons.opacity, color: Color(0xFFFF9800),
        symptom: 'Небольшой расход масла (2.0T)',
        cause: 'Характер турбированного мотора — норма 0.5 л / 5000 км',
        solution: 'Контролировать уровень каждые 3 000 км. Использовать масло Castrol Edge.',
        urgency: 'low',
      ),
      _Problem(
        icon: Icons.local_fire_department, color: Color(0xFFFF9800),
        symptom: 'Течь охлаждающей жидкости',
        cause: 'Прокладка ГБЦ или патрубки системы',
        solution: 'Диагностика. При прокладке — замена с новыми болтами.',
        urgency: 'medium',
      ),
      _Problem(
        icon: Icons.local_car_wash, color: Color(0xFFF44336),
        symptom: 'Ржавчина на кузове, особенно в районе колёс',
        cause: 'Alfa всегда были восприимчивы к коррозии',
        solution: 'Обработка воском каждые полгода. Защита пороговых кромок.',
        urgency: 'medium',
      ),
    ],
    maint: _maintGerman,
    tips: _tipsAlfa,
  ),

  // ─── Jaguar ───
  'jaguar': _Knowledge(
    about: 'Jaguar (JLR, Tata Motors) — британский премиум с богатой историей. XF, F-Pace — современные и элегантные. Дорогое обслуживание, но за качеством.',
    problems: [
      _Problem(
        icon: Icons.link, color: Color(0xFFF44336),
        symptom: 'Стук цепи ГРМ при запуске (3.0 V6)',
        cause: 'Растяжение цепи ГРМ на пробеге 120+ 000 км',
        solution: 'Замена цепного привода ГРМ. Дорогая работа — в цену входит 25–30% сметы работ.',
        urgency: 'high',
      ),
      _Problem(
        icon: Icons.airline_seat_recline_extra, color: Color(0xFFFF9800),
        symptom: 'Функция Air Suspension работает нестабильно (F-Pace)',
        cause: 'Износ компрессора или клапанов подвески',
        solution: 'Диагностика подвески. Замена компрессора или конвертация на пружины.',
        urgency: 'medium',
      ),
      _Problem(
        icon: Icons.opacity, color: Color(0xFFFFC107),
        symptom: 'Течь масла из двигателя',
        cause: 'Прокладка крышки ГБЦ или сальники',
        solution: 'Замена по месту течи. Цены как на премиум-авто.',
        urgency: 'medium',
      ),
    ],
    maint: _maintGerman,
    tips: _tipsJaguar,
  ),

  // ─── Citroën ───
  'citroen': _Knowledge(
    about: 'Citroën — французский бренд с эксцентричным дизайном. C4, C5, Berlingo — практичны и комфортны. Пневматическая подвеска (старые модели) требует контроля.',
    problems: [
      _Problem(
        icon: Icons.settings, color: Color(0xFFF44336),
        symptom: 'Вибрация на холостом ходу 1.2 THP',
        cause: 'Закоксовка дроссельной заслонки',
        solution: 'Чистка дроссельной заслонки. Сброс адаптаций через диагностику.',
        urgency: 'low',
      ),
      _Problem(
        icon: Icons.airline_seat_recline_extra, color: Color(0xFFFF9800),
        symptom: 'Пневмоподвеска опускается (C5 старые)',
        cause: 'Износ воздушных амортизаторов или клапанов',
        solution: 'Замена пневмостоек или конвертация на пружины — дорого.',
        urgency: 'high',
      ),
      _Problem(
        icon: Icons.opacity, color: Color(0xFFFFC107),
        symptom: 'Расход масла 1.6 THP',
        cause: 'Закоксовка маслосъёмных колец',
        solution: 'Промывка (Liqui Moly). При отсутствии эффекта — замена колец.',
        urgency: 'medium',
      ),
    ],
    maint: _maintGeneric,
    tips: _tipsCitrogen,
  ),

  // ─── DS (Citroën premium line) ───
  'ds': _Knowledge(
    about: 'DS (Citroën Collection) — французский премиум-лайн. DS3, DS7 — роскошные с изысканным дизайном. Дорога обслуживаться, использует платформы от Citroën.',
    problems: [
      _Problem(
        icon: Icons.opacity, color: Color(0xFFFF9800),
        symptom: 'Расход масла (1.6 THP)',
        cause: 'Особенность прямовпрыска',
        solution: 'Контролировать уровень. При >0.5л/1000км — диагностика.',
        urgency: 'low',
      ),
      _Problem(
        icon: Icons.settings, color: Color(0xFFFFC107),
        symptom: 'Рывки при переключении автомата',
        cause: 'Загрязнение масла или необходима адаптация',
        solution: 'Замена масла EAT6/EAT8 оригинальным Elf. Адаптация.',
        urgency: 'medium',
      ),
    ],
    maint: _maintGeneric,
    tips: _tipsCitrogen,
  ),

  // ─── MG (Chinese revival) ───
  'mg': _Knowledge(
    about: 'MG (Morris Garages) — возрождённая британская марка (SAIC, Китай). MG5, MG6 — доступные и современные. Ставят на азиатские платформы.',
    problems: [
      _Problem(
        icon: Icons.opacity, color: Color(0xFFFF9800),
        symptom: 'Требует частая замена масла',
        cause: 'Двигатель требователен в СНГ условиях',
        solution: 'Масло 5W-30 каждые 5 000 км. Контролировать уровень.',
        urgency: 'low',
      ),
      _Problem(
        icon: Icons.sync, color: Color(0xFFFFC107),
        symptom: 'Рывки АКПП при старте на холоде',
        cause: 'Особенность коробки в морозную погоду',
        solution: 'Прогревать авто 5 минут перед движением. Обновление ПО.',
        urgency: 'low',
      ),
      _Problem(
        icon: Icons.settings, color: Color(0xFFFFC107),
        symptom: 'Дроссель требует чистки',
        cause: 'Топливо СНГ дешёвое низкого качества',
        solution: 'Чистка дроссельной заслонки каждые 60 000 км.',
        urgency: 'low',
      ),
    ],
    maint: _maintGeneric,
    tips: _tipsMG,
  ),

  // ─── Geely ───
  'geely': _Knowledge(
    about: 'Geely — китайский бренд (Volvo-Geely). Emgrand, Coolray — качественнее Great Wall/Chery. Дизайн привлекательный, технология развивается.',
    problems: [
      _Problem(
        icon: Icons.opacity, color: Color(0xFFFFC107),
        symptom: 'Требует качественное масло',
        cause: 'Двигатели всё ещё требуют ухода',
        solution: 'Масло 5W-30 оригинальное или Mobil 1 каждые 5 000 км.',
        urgency: 'low',
      ),
      _Problem(
        icon: Icons.settings, color: Color(0xFFFFC107),
        symptom: 'Дроссельная заслонка частых закоксовок',
        cause: 'Конструкция и качество топлива СНГ',
        solution: 'Профилактическая чистка каждые 60 000 км.',
        urgency: 'low',
      ),
      _Problem(
        icon: Icons.battery_charging_full, color: Color(0xFFFF9800),
        symptom: 'Проблемы с гибридной батареей (если гибрид)',
        cause: 'Система гибридизации Geely ещё недостаточно отработана',
        solution: 'Диагностика у дилера. При гарантии — замена.',
        urgency: 'medium',
      ),
    ],
    maint: _maintGeneric,
    tips: _tipsGeely,
  ),

  // ─── Chery ───
  'chery': _Knowledge(
    about: 'Chery — китайский бренд (наравне с Geely). Tiggo, Arrizo — популярны в СНГ. Простая конструкция, доступные двигатели, но требуют тщательного ТО.',
    problems: [
      _Problem(
        icon: Icons.opacity, color: Color(0xFFFFC107),
        symptom: 'Требует частая замена масла',
        cause: 'Двигатели чувствительны к качеству',
        solution: 'Масло 5W-30 каждые 5 000 км. Проверять каждые 2 500 км.',
        urgency: 'low',
      ),
      _Problem(
        icon: Icons.settings, color: Color(0xFFFFC107),
        symptom: 'Закоксовка форсунок и дроссельной заслонки',
        cause: 'Топливо СНГ низкого качества',
        solution: 'Промывка форсунок и чистка дроссельной заслонки каждые 60 000 км.',
        urgency: 'low',
      ),
      _Problem(
        icon: Icons.vibration, color: Color(0xFFFFC107),
        symptom: 'Хруст/скрип передней подвески',
        cause: 'Быстрый износ сайлентблоков',
        solution: 'Замена сайлентблоков рычагов передней подвески.',
        urgency: 'medium',
      ),
    ],
    maint: _maintGeneric,
    tips: _tipsChery,
  ),

  // ─── Great Wall / Haval ───
  'haval': _Knowledge(
    about: 'Haval (Great Wall Motors) — китайский SUV бренд. H6, H9 — популярные в СНГ. Конструкция простая, двигатели надёжны для цены.',
    problems: [
      _Problem(
        icon: Icons.opacity, color: Color(0xFFFFC107),
        symptom: 'Требует частая замена масла',
        cause: 'Двигатель требует ухода',
        solution: 'Масло 5W-30 каждые 5–10 000 км.',
        urgency: 'low',
      ),
      _Problem(
        icon: Icons.settings, color: Color(0xFFFFC107),
        symptom: 'Требуется профилактическая чистка топливной системы',
        cause: 'Топливо СНГ низкого качества засоряет форсунки',
        solution: 'Промывка форсунок и очистка дроссельной заслонки каждые 60–80 тыс. км.',
        urgency: 'low',
      ),
      _Problem(
        icon: Icons.rotate_right, color: Color(0xFFFFC107),
        symptom: 'Люфт в рулевом управлении',
        cause: 'Износ рулевых тяг',
        solution: 'Замена рулевых наконечников. Доступная работа.',
        urgency: 'medium',
      ),
    ],
    maint: _maintGeneric,
    tips: _tipsGreatWall,
  ),

  // ─── Genesis (Hyundai luxury line) ───
  'genesis': _Knowledge(
    about: 'Genesis (Hyundai Motor Group) — премиум-линия на платформе Н-车. G70, GV70 — роскошные седан и кроссовер. Электрическое оборудование продвинутое.',
    problems: [
      _Problem(
        icon: Icons.opacity, color: Color(0xFFFF9800),
        symptom: 'Требует премиум-масло и тщательное ТО',
        cause: 'Премиум-позиционирование',
        solution: 'Масло 5W-30/5W-40 оригинальное каждые 7 500 км. Только дилер для диагностики.',
        urgency: 'low',
      ),
      _Problem(
        icon: Icons.airline_seat_recline_extra, color: Color(0xFFFF9800),
        symptom: 'Пневмоподвеска требует регулировки',
        cause: 'Система регуляции высоты требует контроля',
        solution: 'Каждые 30 000 км проверять давление. По мере износа — замена пневмостоек.',
        urgency: 'medium',
      ),
      _Problem(
        icon: Icons.sync, color: Color(0xFFFFC107),
        symptom: 'Толчки АКПП 8-ступ при переключении',
        cause: 'Необходимость адаптации или загрязнение масла',
        solution: 'Замена масла 8-ступ с адаптацией. Только дилер.',
        urgency: 'medium',
      ),
    ],
    maint: _maintKorean,
    tips: _tipsGenesis,
  ),

  // ─── XPeng (Chinese EV) ───
  'xpeng': _Knowledge(
    about: 'XPeng — китайский премиум-EV (Tesla конкурент). P7, P5 — стильные с продвинутым ПО. Батарея CATL, быстрая зарядка, Autopilot аналог включён.',
    problems: [
      _Problem(
        icon: Icons.battery_charging_full, color: Color(0xFFF44336),
        symptom: 'Батарея быстро деградирует зимой',
        cause: 'Температурные колебания и частая быстрая зарядка',
        solution: 'Используйте домашнюю зарядку на 80%. Предварительно разогревайте батарею в мороз.',
        urgency: 'high',
      ),
      _Problem(
        icon: Icons.blur_on, color: Color(0xFFFF9800),
        symptom: 'Дальность упала на 30–40% в холоде',
        cause: 'Батарея теряет мощность при температурах ниже 0°C',
        solution: 'Нормально для Li-ion. Планируйте маршруты с запасом. Используйте режим Eco.',
        urgency: 'low',
      ),
      _Problem(
        icon: Icons.settings, color: Color(0xFFFFC107),
        symptom: 'Нестабильность Autopilot в сложных условиях',
        cause: 'Загрязнение камер или нужно обновление ПО',
        solution: 'Обновляйте ПО сразу (OTA). Очищайте камеры от грязи.',
        urgency: 'low',
      ),
    ],
    maint: _maintGeneric,
    tips: _tipsXPeng,
  ),

  // ─── Nio (Premium Chinese EV) ───
  'nio': _Knowledge(
    about: 'Nio — премиальный китайский EV (конкурент Mercedes EQE). ES6, ES8 — люкс-класс. Система Battery Swap (замена батареи за 5 мин) уникальна. ПО создан совместно с Baidu.',
    problems: [
      _Problem(
        icon: Icons.battery_charging_full, color: Color(0xFFFF9800),
        symptom: 'Батарея деградирует после 150–200 000 км пути',
        cause: 'При использовании Battery Swap батареи меняются — наработка суммируется',
        solution: 'Это нормально для неё системы Nio. При сильной деградации — замена батареи.',
        urgency: 'medium',
      ),
      _Problem(
        icon: Icons.blur_on, color: Color(0xFFFF9800),
        symptom: 'Дальность зимой падает на 40–50%',
        cause: 'Батарея, кондиционер салона, охлаждение прототипов',
        solution: 'Используйте режим Eco и предварительный подогрев. Это нормально.',
        urgency: 'low',
      ),
      _Problem(
        icon: Icons.settings, color: Color(0xFFFFC107),
        symptom: 'Сложности с обслуживанием вне Китая',
        cause: 'Редкие сервис-центры Nio в СНГ',
        solution: 'Требует профилактика. Запасные части сложно найти. Рекомендуется OEM запчасти.',
        urgency: 'high',
      ),
    ],
    maint: _maintGeneric,
    tips: _tipsNio,
  ),

  // ─── Polestar (Volvo EV performance brand) ───
  'polestar': _Knowledge(
    about: 'Polestar — быстрая EV-линия Volvo (совместно с Geely). Polestar 3/4 — премиальные EV. Дизайн, производительность, безопасность на уровне кроме батареи.',
    problems: [
      _Problem(
        icon: Icons.battery_charging_full, color: Color(0xFFFF9800),
        symptom: 'Батарея деградирует заметнее на быстрой зарядке',
        cause: 'Даже премиальные батареи теряют 1–2% в год с быстрой зарядкой',
        solution: 'Минимизируйте Supercharger. Используйте домашнюю зарядку на 80%.',
        urgency: 'low',
      ),
      _Problem(
        icon: Icons.opacity, color: Color(0xFFFFC107),
        symptom: 'Требуется периодическая проверка жидкости охлаждения батареи',
        cause: 'Батарея требует активного охлаждения в большем мотор-спорте',
        solution: 'Проверка и долив охлаждающей жидкости каждые 2 года у дилера.',
        urgency: 'low',
      ),
      _Problem(
        icon: Icons.blur_on, color: Color(0xFFFF9800),
        symptom: 'Производительность падает с нагревом батареи',
        cause: 'Дроссель-система терморегуляции срабатывает на интенсивной езде',
        solution: 'После агрессивного вождения дайте батарее остыть 30 минут перед зарядкой.',
        urgency: 'low',
      ),
    ],
    maint: _maintGeneric,
    tips: _tipsPolestar,
  ),

  // ─── Acura (Honda luxury) ───
  'acura': _Knowledge(
    about: 'Acura — премиум-линия Honda (Япония/США). TLX, RDX, MDX — роскошные с надёжными двигателями. V6 / Turbo 2.0 — проверенные моторы Honda.',
    problems: [
      _Problem(
        icon: Icons.sync, color: Color(0xFFFF9800),
        symptom: 'Рывки седанов с CVT при старте',
        cause: 'Характер вариатора на холоде',
        solution: 'Прогревать авто 3–5 минут перед движением. Соблюдать интервалы замены масла CVT.',
        urgency: 'low',
      ),
      _Problem(
        icon: Icons.opacity, color: Color(0xFFFFC107),
        symptom: 'Небольшой расход масла (V6)',
        cause: '0.5 л / 5000 км для V6 считается нормальным',
        solution: 'Контролировать уровень каждые 3 000 км.',
        urgency: 'low',
      ),
      _Problem(
        icon: Icons.rotate_right, color: Color(0xFFFF9800),
        symptom: 'Стук передней подвески после 80 000 км',
        cause: 'Износ стоек стабилизатора',
        solution: 'Замена стоек стабилизатора. Недорогая работа.',
        urgency: 'medium',
      ),
    ],
    maint: _maintJapanese,
    tips: _tipsToyota,
  ),

  // ─── BYD (Chinese EV leader) ───
  'byd': _Knowledge(
    about: 'BYD — крупнейший китайский EV (больше Tesla по продажам). Qin, Song, Yuan — электрические и гибридные. Батареи LFP собственного производства надёжны.',
    problems: [
      _Problem(
        icon: Icons.battery_charging_full, color: Color(0xFFFFC107),
        symptom: 'Батарея LFP заряжается медленнее, чем NCA/NCM',
        cause: 'Технология LFP имеет меньше плотность энергии',
        solution: 'Нормально для LFP. Планируйте больше времени на зарядку.',
        urgency: 'low',
      ),
      _Problem(
        icon: Icons.blur_on, color: Color(0xFFFF9800),
        symptom: 'Дальность зимой падает на 20–30%',
        cause: 'Батарея LFP менее чувствительна к холоду, чем Li-ion',
        solution: 'LFP держит дальность лучше других в мороз. Всё равно планируйте с запасом.',
        urgency: 'low',
      ),
      _Problem(
        icon: Icons.settings, color: Color(0xFFFFC107),
        symptom: 'Редкие сервис-центры вне Китая',
        cause: 'BYD относительно новый экспортёр',
        solution: 'Требуется тщательная профилактика. Запасные части найти сложнее.',
        urgency: 'medium',
      ),
    ],
    maint: _maintGeneric,
    tips: _tipsChery,
  ),

  // ─── Changan (Chinese mainstream) ───
  'changan': _Knowledge(
    about: 'Changan — крупный производитель в Китае с расширяющимся экспортом. Атмосферные и турбо двигатели рабоче-крестьянского класса.',
    problems: [
      _Problem(
        icon: Icons.settings, color: Color(0xFFFF9800),
        symptom: 'Вибрация на холостом ходу после 50 000 км',
        cause: 'Закоксовка дроссельной заслонки',
        solution: 'Чистка дроссельной заслонки через сканер. Замена воздушного фильтра.',
        urgency: 'low',
      ),
      _Problem(
        icon: Icons.opacity, color: Color(0xFFFF5722),
        symptom: 'Пятна масла спереди под двигателем',
        cause: 'Износ прокладок поддона картера',
        solution: 'Замена прокладки поддона. Часто требуется повторная затяжка после 100 км.',
        urgency: 'medium',
      ),
      _Problem(
        icon: Icons.sync, color: Color(0xFF9E9E9E),
        symptom: 'Рывки при разгоне с 1-й на 2-ю передачу',
        cause: 'Требуется адаптация АКПП',
        solution: 'Обновить ПО через сканер. Или: разъём OBD, ключ ON, ждать 10 сек.',
        urgency: 'low',
      ),
    ],
    maint: _maintGeneric,
    tips: _tipsChangan,
  ),

  // ─── Wuling (Chinese budget) ───
  'wuling': _Knowledge(
    about: 'Wuling — бюджетный бренд SAIC-GM-Wuling. Мини-вэны и компактные авто со слабой шумоизоляцией но дешевого обслуживания.',
    problems: [
      _Problem(
        icon: Icons.opacity, color: Color(0xFFFF9800),
        symptom: 'Быстрое появление нагара на форсунках',
        cause: 'Качество топлива на АЗС СНГ ниже стандартов',
        solution: 'Использовать присадки в топливо или периодическая чистка форсунок.',
        urgency: 'low',
      ),
      _Problem(
        icon: Icons.rotate_right, color: Color(0xFFF44336),
        symptom: 'Щелчки в районе ШРУСа при полном вывороте руля',
        cause: 'Начальный износ внешних ШРУСов',
        solution: 'Смазать шарниры через пыльник или заменить пыльник + шрус.',
        urgency: 'high',
      ),
      _Problem(
        icon: Icons.settings, color: Color(0xFF9E9E9E),
        symptom: 'Скрип резины подвески при повороте на месте',
        cause: 'Недостаток смазки в шарнирах подвески',
        solution: 'Смазка всех шарниров подвески регулярно (каждые 30 000 км).',
        urgency: 'low',
      ),
    ],
    maint: _maintGeneric,
    tips: _tipsWuling,
  ),

  // ─── Li Auto (Chinese EREV) ───
  'li auto': _Knowledge(
    about: 'Li Auto — производитель гибридов-расширителей (EREV). Двигатель включается только для генерации энергии — система сложна.',
    problems: [
      _Problem(
        icon: Icons.battery_charging_full, color: Color(0xFFFFC107),
        symptom: 'Неожиданное снижение батареи при парковке',
        cause: 'Система управления теплом батареи работает в фоне',
        solution: 'Проверить температуру батареи. Припаркуйте в тени. Контроль нормален.',
        urgency: 'low',
      ),
      _Problem(
        icon: Icons.blur_on, color: Color(0xFFFF9800),
        symptom: 'Генератор включается слишком часто зимой',
        cause: 'Холодная батарея требует подогрева от генератора',
        solution: 'Нормально. Используйте предварительный подогрев от дома перед выездом.',
        urgency: 'low',
      ),
      _Problem(
        icon: Icons.settings, color: Color(0xFF2196F3),
        symptom: 'Вибрация при запуске двигателя генератора',
        cause: 'Система EREV включает маленький турбо-двигатель для выработки энергии',
        solution: 'Нормально. Виброизоляция слабая на Li Auto. Это особенность.',
        urgency: 'low',
      ),
    ],
    maint: _maintGeneric,
    tips: _tipsLiAuto,
  ),

  // ─── Avatr (Chinese premium EV) ───
  'avatr': _Knowledge(
    about: 'Avatr — премиум-бренд с батареями CATL и сенсорной панелью во весь экран. Автопилот требует постоянного контроля.',
    problems: [
      _Problem(
        icon: Icons.battery_charging_full, color: Color(0xFFFFC107),
        symptom: 'Батарея CATL деградирует быстрее чем Tesla',
        cause: 'CATL менее оптимизирована для длительной зарядки',
        solution: 'Минимизируйте быструю зарядку. Используйте домашнюю — только она.',
        urgency: 'medium',
      ),
      _Problem(
        icon: Icons.settings, color: Color(0xFF2196F3),
        symptom: 'Сенсорная панель зависает при навигации',
        cause: 'Программный сбой ОС на основе базовой Android',
        solution: 'Перезагрузить систему (долгое нажатие на кнопку). Обновить ПО.',
        urgency: 'medium',
      ),
      _Problem(
        icon: Icons.blur_on, color: Color(0xFFFF9800),
        symptom: 'Система адаптивного круиз-контроля теряет машину впереди',
        cause: 'Камеры требуют калибровки при замене',
        solution: 'Проведите калибровку камер через сервис.',
        urgency: 'high',
      ),
    ],
    maint: _maintGeneric,
    tips: _tipsAvatar,
  ),

  // ─── Neta (Chinese budget EV) ───
  'neta': _Knowledge(
    about: 'Neta — бюджетный китайский EV от Hozon auto. Батарея CATL или собственной разработки. Быстро развивающаяся марка.',
    problems: [
      _Problem(
        icon: Icons.battery_charging_full, color: Color(0xFFFFC107),
        symptom: 'Дальность в зимний период падает на 40–50%',
        cause: 'Батарея теряет эффективность при холоде',
        solution: 'Предварительный подогрев батареи перед выездом. Планируйте маршруты с запасом.',
        urgency: 'low',
      ),
      _Problem(
        icon: Icons.settings, color: Color(0xFF2196F3),
        symptom: 'Ошибка в системе управления батареей',
        cause: 'Программный сбой BMS',
        solution: 'Перезагрузить систему через ключ. Если не помогает — сервис.',
        urgency: 'medium',
      ),
      _Problem(
        icon: Icons.blur_on, color: Color(0xFFFF9800),
        symptom: 'Автомобиль не полностью заряжается на медленной зарядке',
        cause: 'Ограничение BMS для защиты батареи',
        solution: 'Используйте режим быстрой зарядки 1–2 раза в неделю. Нормально.',
        urgency: 'low',
      ),
    ],
    maint: _maintGeneric,
    tips: _tipsNeta,
  ),

  // ─── Leapmotor (Chinese compact EV) ───
  'leapmotor': _Knowledge(
    about: 'Leapmotor — компактные электромобили с хорошей ёмкостью батареи. Быстро развивается (партнёр Geely-Volvo).',
    problems: [
      _Problem(
        icon: Icons.battery_charging_full, color: Color(0xFFFFC107),
        symptom: 'Батарея быстро деградирует при ежедневной быстрой зарядке',
        cause: 'Частая быстрая зарядка — враг батареи',
        solution: 'Минимизируйте быструю зарядку. Используйте 3.6-6.6 кВт домашнюю зарядку.',
        urgency: 'medium',
      ),
      _Problem(
        icon: Icons.blur_on, color: Color(0xFFFF9800),
        symptom: 'Мотор издаёт гудящий звук при разгоне',
        cause: 'Нормальный звук для электромотора — высокие обороты',
        solution: 'Это не дефект. Звезды стабилизируют звук. Сер.вис не требуется.',
        urgency: 'low',
      ),
      _Problem(
        icon: Icons.settings, color: Color(0xFF2196F3),
        symptom: 'Система рекуперативного торможения становится мягче со временем',
        cause: 'Адаптация системы к стилю вождения',
        solution: 'Проведите переобучение системы через меню. Это нормально.',
        urgency: 'low',
      ),
    ],
    maint: _maintGeneric,
    tips: _tipsLeapmotor,
  ),

  // ─── VAZ (Soviet & Russian classic cars) ───
  'vaz': _Knowledge(
    about: 'ВАЗ — легендарные советские и русские автомобили. 2101–2107 — карбюраторные бюджетные авто с простой конструкцией. 2109–2112 — инжекторные версии. Ремонт можно делать в гараже самостоятельно.',
    problems: [
      _Problem(
        icon: Icons.local_car_wash, color: Color(0xFFF44336),
        symptom: 'Ржавчина кузова — сквозные отверстия снизу или в углах дверей',
        cause: 'Коррозия металла кузова при отсутствии защиты',
        solution: 'Зачистить очаги ржавчины, загрунтовать, зашпатлевать. Обработка днища мастикой обязательна.',
        urgency: 'high',
      ),
      _Problem(
        icon: Icons.settings, color: Color(0xFFFF9800),
        symptom: 'Нестабильный холостой ход (карбюратор)',
        cause: 'Засорение жиклёров, дроссельной заслонки карбюратора',
        solution: 'Регулировка винтов качества и количества смеси (заводской регулировщик или руководство). Промывка газо.',
        urgency: 'low',
      ),
      _Problem(
        icon: Icons.opacity, color: Color(0xFFFFC107),
        symptom: 'Течь масла из-под поддона картера',
        cause: 'Износ прокладки поддона или ослабление болтов',
        solution: 'Замена прокладки поддона. Затяжка болтов по крутящему моменту (15–20 Нм).',
        urgency: 'medium',
      ),
      _Problem(
        icon: Icons.disc_full, color: Color(0xFFFF9800),
        symptom: 'Тормоза «мягкие» или вибрируют при торможении',
        cause: 'Воздух в тормозной системе или износ колодок/барабанов',
        solution: 'Прокачка тормозной системы. Замена тормозных колодок (Ferodo, ATE). Если барабаны — проточка.',
        urgency: 'high',
      ),
    ],
    maint: _maintGeneric,
    tips: _tipsVAZ,
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
//  Brand aliases (Russian & common abbreviations → DB key)
// ──────────────────────────────────────────────
const _brandAliases = <String, String>{
  // BMW
  'бмв': 'bmw',
  // Toyota
  'тойота': 'toyota',
  'тоёта': 'toyota',
  // Mercedes
  'мерседес': 'mercedes',
  'мерс': 'mercedes',
  'мерседес-бенц': 'mercedes',
  'mercedes-benz': 'mercedes',
  // Volkswagen
  'фольксваген': 'volkswagen',
  'фольцваген': 'volkswagen',
  'vw': 'volkswagen',
  // Hyundai
  'хёндай': 'hyundai',
  'хундай': 'hyundai',
  'хуандай': 'hyundai',
  'хендай': 'hyundai',
  // Kia
  'киа': 'kia',
  // Nissan
  'ниссан': 'nissan',
  'нисан': 'nissan',
  // Honda
  'хонда': 'honda',
  // Subaru
  'субару': 'subaru',
  // Lexus
  'лексус': 'lexus',
  // Mitsubishi
  'митсубиши': 'mitsubishi',
  'мицубиши': 'mitsubishi',
  'митсубиси': 'mitsubishi',
  // Chevrolet
  'шевроле': 'chevrolet',
  // Lada / VAZ
  'лада': 'lada',
  // Toyota models
  'камри': 'toyota camry',
  'рав4': 'toyota rav4',
  'rav4': 'toyota rav4',
  'land cruiser': 'toyota land cruiser',
  'ленд крузер': 'toyota land cruiser',
  'королла': 'toyota corolla',
  'corolla': 'toyota corolla',
  'хайлендер': 'toyota highlander',
  'highlander': 'toyota highlander',
  // Audi
  'ауди': 'audi',
  'audi a4': 'audi a4',
  'ауди а4': 'audi a4',
  'audi q5': 'audi q5',
  'ауди q5': 'audi q5',
  'ауди кю5': 'audi q5',
  // Mazda
  'мазда': 'mazda',
  'cx-5': 'mazda cx-5',
  'cx5': 'mazda cx-5',
  'мазда сх5': 'mazda cx-5',
  'мазда cx5': 'mazda cx-5',
  // Skoda
  'шкода': 'skoda',
  'октавия': 'skoda octavia',
  'octavia': 'skoda octavia',
  // Renault
  'рено': 'renault',
  'рнаулт': 'renault',
  'дастер': 'renault',
  'duster': 'renault',
  'логан': 'renault',
  'logan': 'renault',
  // Ford
  'форд': 'ford',
  // Volvo
  'вольво': 'volvo',
  // Land Rover
  'ленд ровер': 'land rover',
  'ренджровер': 'land rover',
  'range rover': 'land rover',
  'рэнджровер': 'land rover',
  'дискавери': 'land rover',
  'discovery': 'land rover',
  // Porsche
  'порше': 'porsche',
  'кайен': 'porsche',
  'cayenne': 'porsche',
  // Jeep
  'джип': 'jeep',
  'grand cherokee': 'jeep',
  'гранд чероки': 'jeep',
  'вранглер': 'jeep',
  'wrangler': 'jeep',
  // Suzuki
  'сузуки': 'suzuki',
  'витара': 'suzuki',
  'vitara': 'suzuki',
  'джимни': 'suzuki',
  'jimny': 'suzuki',
  // Opel
  'опель': 'opel',
  'астра': 'opel',
  'инсигния': 'opel',
  // Peugeot
  'пежо': 'peugeot',
  'пэжо': 'peugeot',
  // Infiniti
  'инфинити': 'infiniti',
  'инфинит': 'infiniti',
  // UAZ
  'уаз': 'uaz',
  'patriot': 'uaz',
  'патриот': 'uaz',
  // Kia models
  'спортейдж': 'kia sportage',
  'спортаж': 'kia sportage',
  'sportage': 'kia sportage',
  'рио': 'kia rio',
  'rio': 'kia rio',
  // Hyundai models
  'туксон': 'hyundai tucson',
  'tucson': 'hyundai tucson',
  'элантра': 'hyundai',
  'elantra': 'hyundai',
  'соната': 'hyundai',
  // VW models
  'гольф': 'volkswagen golf',
  'golf': 'volkswagen golf',
  'поло': 'volkswagen',
  'polo': 'volkswagen',
  // BMW models
  'бмв х5': 'bmw x5',
  'бмв x5': 'bmw x5',
  // Cyrillic model letter aliases (for _getKnowledge model normalisation)
  'х5': 'x5',
  'х6': 'x6',
  'х3': 'x3',
  'х7': 'x7',
  // Mercedes models
  'mercedes c': 'mercedes c',
  'мерседес с': 'mercedes c',
  'мерс с': 'mercedes c',
  'c-class': 'mercedes c',
  'с-класс': 'mercedes c',
  'mercedes gle': 'mercedes gle',
  'мерседес гле': 'mercedes gle',
  'gle': 'mercedes gle',
  // MINI
  'мини': 'mini',
  'mini': 'mini',
  // Tesla
  'тесла': 'tesla',
  'model 3': 'tesla model 3',
  'модель 3': 'tesla model 3',
  'model 3 performance': 'tesla model 3',
  'model y': 'tesla',
  // Fiat
  'фиат': 'fiat',
  'панда': 'fiat panda',
  'panda': 'fiat panda',
  'типо': 'fiat',
  'tipo': 'fiat',
  '500': 'fiat',
  // Alfa Romeo
  'альфа ромео': 'alfa romeo',
  'альфа': 'alfa romeo',
  'alfa': 'alfa romeo',
  'альфа ромео джулия': 'alfa romeo',
  'цельвая': 'alfa romeo',
  // Jaguar
  'ягуар': 'jaguar',
  'джагуар': 'jaguar',
  'экседф': 'jaguar',
  'xf': 'jaguar',
  'ф-пейс': 'jaguar',
  'f-pace': 'jaguar',
  // Citroën
  'ситроен': 'citroen',
  'citroen': 'citroen',
  'си': 'citroen',
  'c4': 'citroen',
  'c5': 'citroen',
  'берлинго': 'citroen',
  // DS
  'ds': 'ds',
  'дс': 'ds',
  // MG
  'mg': 'mg',
  'эмжи': 'mg',
  'mg5': 'mg',
  'mg6': 'mg',
  // Geely
  'гили': 'geely',
  'геели': 'geely',
  'emgrand': 'geely',
  'эмгренд': 'geely',
  'coolray': 'geely',
  'кулрей': 'geely',
  // Chery
  'чери': 'chery',
  'чери тиггоколя': 'chery',
  'chery tiggo': 'chery',
  'тиггo': 'chery',
  'tiggo': 'chery',
  'аррисо': 'chery',
  'arrizo': 'chery',
  // Great Wall / Haval
  'грейт вол': 'haval',
  'грет вол': 'haval',
  'хавал': 'haval',
  'haval': 'haval',
  'h6': 'haval',
  'h9': 'haval',
  // Genesis
  'генезис': 'genesis',
  'genesis': 'genesis',
  'генезис гв708': 'genesis',
  'gv70': 'genesis',
  // XPeng
  'экспенг': 'xpeng',
  'экспендж': 'xpeng',
  'xpeng': 'xpeng',
  'xpeng p7': 'xpeng',
  'р7': 'xpeng',
  // Nio
  'нио': 'nio',
  'nio': 'nio',
  'es6': 'nio',
  'эс6': 'nio',
  'es8': 'nio',
  'эс8': 'nio',
  // Polestar
  'полстар': 'polestar',
  'polestar': 'polestar',
  'полюстар': 'polestar',
  // Acura
  'акура': 'acura',
  'acura': 'acura',
  'tlx': 'acura',
  'rdx': 'acura',
  'mdx': 'acura',
  // BYD
  'byd': 'byd',
  'бид': 'byd',
  'qin': 'byd',
  'song': 'byd',
  'yuan': 'byd',
  // Changan
  'чанган': 'changan',
  'changan': 'changan',
  'cs35': 'changan',
  'cs75': 'changan',
  'cs95': 'changan',
  'ч35': 'changan',
  // Wuling
  'вулинг': 'wuling',
  'wuling': 'wuling',
  'hongguang': 'wuling',
  'хонгуанг': 'wuling',
  // Li Auto
  'ли ауто': 'li auto',
  'li auto': 'li auto',
  'лиауто': 'li auto',
  'one': 'li auto',
  'плюс': 'li auto',
  'x90': 'li auto',
  // Avatr
  'аватр': 'avatr',
  'avatr': 'avatr',
  'авatar': 'avatr',
  '11': 'avatr',
  '12': 'avatr',
  // Neta
  'нета': 'neta',
  'neta': 'neta',
  'v': 'neta',
  'u': 'neta',
  'z': 'neta',
  // Leapmotor
  'лепмотор': 'leapmotor',
  'leapmotor': 'leapmotor',
  'лип': 'leapmotor',
  't03': 'leapmotor',
  's01': 'leapmotor',
  // VAZ
  'ваз': 'vaz',
  'vaz': 'vaz',
  'вазовский': 'vaz',
  '2101': 'vaz',
  '2102': 'vaz',
  '2103': 'vaz',
  '2105': 'vaz',
  '2106': 'vaz',
  '2107': 'vaz',
  '2109': 'vaz',
  '21099': 'vaz',
  '2110': 'vaz',
  '2112': 'vaz',
  'девятка': 'vaz',
  'десятка': 'vaz',
};

// Порядок приоритетов поиска:
// 1. brandField as-is (lowercase) — в случае если уже написано "toyota camry"
// 2. Полное поле brand нормализовано (алиасы применены к каждому слову)
// 3. Первое слово + второе слово нормализованы (brand + model)
// 4. Только первое слово нормализовано (brand-only)
// 5. _generic

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

    // car.brand — что ввёл пользователь: "BMW X5", "бмв х5", "Toyota Camry"
    final raw = car.brand.toLowerCase().trim();
    if (raw.isEmpty) return _db['_generic']!;

    // 1. Прямое совпадение (например, "toyota camry", "bmw x5")
    if (_db.containsKey(raw)) return _db[raw]!;

    // 2. Алиас всей строки (например, "ленд крузер" → "toyota land cruiser")
    if (_brandAliases.containsKey(raw)) {
      final resolved = _brandAliases[raw]!;
      if (_db.containsKey(resolved)) return _db[resolved]!;
    }

    final parts = raw.split(RegExp(r'\s+'));
    final first = parts[0];
    final normFirst = _brandAliases[first] ?? first;

    if (parts.length >= 2) {
      final secondRaw = parts[1];
      // Нормализуем второе слово (кириллица → латиница, например "х5" → "x5")
      final normSecond = _brandAliases[secondRaw] ?? secondRaw;

      // 3a. normFirst + исходное второе слово ("bmw" + "x5")
      final key1 = '$normFirst $secondRaw';
      if (_db.containsKey(key1)) return _db[key1]!;

      // 3b. normFirst + нормализованное второе слово ("bmw" + "x5" из "х5")
      if (normSecond != secondRaw) {
        final key2 = '$normFirst $normSecond';
        if (_db.containsKey(key2)) return _db[key2]!;
      }

      // 3c. Попытка поиска через 3 слова (например, "toyota land cruiser")
      if (parts.length >= 3) {
        final key3 = '$normFirst $secondRaw ${parts[2]}';
        if (_db.containsKey(key3)) return _db[key3]!;
        final key3n = '$normFirst $normSecond ${parts[2]}';
        if (_db.containsKey(key3n)) return _db[key3n]!;
      }
    }

    // 4. Только нормализованная марка (например, "бмв" → "bmw")
    if (_db.containsKey(normFirst)) return _db[normFirst]!;

    return _db['_generic']!;
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
