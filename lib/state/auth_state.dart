import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/config/env.dart';

enum AppRole { self, patient, therapist }

extension AppRoleLabel on AppRole {
  String get dbValue => switch (this) {
    AppRole.self => 'self',
    AppRole.patient => 'patient',
    AppRole.therapist => 'therapist',
  };

  String get label => switch (this) {
    AppRole.self => 'Pengguna',
    AppRole.patient => 'Pasien',
    AppRole.therapist => 'Terapis',
  };

  static AppRole fromDb(String? value) => switch (value) {
    'therapist' => AppRole.therapist,
    'patient' => AppRole.patient,
    _ => AppRole.self,
  };
}

class AppRoleNotifier extends Notifier<AppRole> {
  @override
  AppRole build() => AppRole.self;

  void setRole(AppRole role) => state = role;
}

final appRoleProvider = NotifierProvider<AppRoleNotifier, AppRole>(
  AppRoleNotifier.new,
);

class CurrentUser {
  const CurrentUser({
    required this.id,
    required this.name,
    required this.email,
  });

  final String id;
  final String name;
  final String email;
}

final currentUserProvider = NotifierProvider<CurrentUserNotifier, CurrentUser?>(
  CurrentUserNotifier.new,
);

class CurrentUserNotifier extends Notifier<CurrentUser?> {
  @override
  CurrentUser? build() => null;

  void setUser(CurrentUser? user) => state = user;
}

/// Mengambil role pengguna dari tabel `profiles` di Supabase.
/// Untuk demo/mock (tanpa Supabase) selalu `self`.
Future<AppRole> resolveCurrentRole() async {
  if (!Env.hasSupabase) return AppRole.self;
  try {
    final client = Supabase.instance.client;
    final user = client.auth.currentUser;
    if (user == null) return AppRole.self;
    final row = await client
        .from('profiles')
        .select('role')
        .eq('id', user.id)
        .maybeSingle();
    return AppRoleLabel.fromDb(row?['role'] as String?);
  } catch (_) {
    return AppRole.self;
  }
}

/// Mengambil nama & email pengguna yang sedang login (jika ada).
Future<CurrentUser?> resolveCurrentUser() async {
  if (!Env.hasSupabase) return null;
  try {
    final client = Supabase.instance.client;
    final user = client.auth.currentUser;
    if (user == null) return null;
    String name = (user.userMetadata?['full_name'] as String?)?.trim() ?? '';
    if (name.isEmpty) {
      try {
        final row = await client
            .from('profiles')
            .select('full_name')
            .eq('id', user.id)
            .maybeSingle();
        name = (row?['full_name'] as String?)?.trim() ?? '';
      } catch (_) {
        // abaikan
      }
    }
    if (name.isEmpty) name = user.email?.split('@').first ?? 'Pengguna Formly';
    return CurrentUser(id: user.id, name: name, email: user.email ?? '');
  } catch (_) {
    return null;
  }
}
