import '../../state/auth_state.dart';

class UserProfile {
  const UserProfile({
    required this.id,
    required this.fullName,
    required this.role,
    this.createdAt,
  });

  final String id;
  final String fullName;
  final AppRole role;
  final DateTime? createdAt;

  String get firstName {
    final name = fullName.trim();
    if (name.isEmpty) return 'Sobat Formly';
    return name.split(RegExp(r'\s+')).first;
  }

  String get initials {
    final parts = fullName
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) return 'F';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }
}

class DayStat {
  const DayStat({
    required this.date,
    this.score = 0,
    this.reps = 0,
    this.sessions = 0,
  });

  final DateTime date;
  final int score;
  final int reps;
  final int sessions;

  String get shortLabel => const ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'][date.weekday - 1];
}

class UserDashboard {
  const UserDashboard({
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.freezes = 0,
    this.xp = 0,
    this.totalSessions = 0,
    this.todaySessions = 0,
    this.week = const [],
    this.activeDays = const [],
    this.badges = const {},
  });

  final int currentStreak;
  final int longestStreak;
  final int freezes;
  final int xp;
  final int totalSessions;
  final int todaySessions;

  /// Tujuh hari terakhir, Senin..Minggu pada minggu berjalan.
  final List<DayStat> week;

  /// Status aktif untuk 7 hari pada minggu berjalan (index 0 = Senin).
  final List<bool> activeDays;

  /// Badge id yang sudah terbuka.
  final Set<String> badges;

  int get level => (xp ~/ 500) + 1;
  int get xpIntoLevel => xp % 500;
  int get xpForNextLevel => 500;

  DayStat get today {
    if (week.isEmpty) {
      return DayStat(date: DateTime.now());
    }
    final now = DateTime.now();
    for (final day in week) {
      if (day.date.year == now.year &&
          day.date.month == now.month &&
          day.date.day == now.day) {
        return day;
      }
    }
    return week.last;
  }

  UserDashboard copyWith({
    int? currentStreak,
    int? longestStreak,
    int? freezes,
    int? xp,
    int? totalSessions,
    int? todaySessions,
    List<DayStat>? week,
    List<bool>? activeDays,
    Set<String>? badges,
  }) {
    return UserDashboard(
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      freezes: freezes ?? this.freezes,
      xp: xp ?? this.xp,
      totalSessions: totalSessions ?? this.totalSessions,
      todaySessions: todaySessions ?? this.todaySessions,
      week: week ?? this.week,
      activeDays: activeDays ?? this.activeDays,
      badges: badges ?? this.badges,
    );
  }
}
