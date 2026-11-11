const _weekdaysId = [
  'Senin',
  'Selasa',
  'Rabu',
  'Kamis',
  'Jumat',
  'Sabtu',
  'Minggu',
];

const _monthsId = [
  'Januari',
  'Februari',
  'Maret',
  'April',
  'Mei',
  'Juni',
  'Juli',
  'Agustus',
  'September',
  'Oktober',
  'November',
  'Desember',
];

String formattedDateId(DateTime date) {
  final weekday = _weekdaysId[date.weekday - 1];
  final month = _monthsId[date.month - 1];
  return '$weekday, ${date.day} $month';
}

String get todayId => formattedDateId(DateTime.now());
