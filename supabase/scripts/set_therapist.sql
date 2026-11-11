-- ============================================================================
-- FORMLY — Kelola role terapis (jalankan di Supabase SQL Editor)
-- ============================================================================

-- 1) Lihat semua user + role saat ini
select
  p.id,
  p.full_name,
  p.role,
  u.email,
  p.created_at
from public.profiles p
join auth.users u on u.id = p.id
order by p.created_at desc;

-- 2) Jadikan TERAPIS berdasarkan email
update public.profiles p
set role = 'therapist',
    updated_at = now()
from auth.users u
where u.id = p.id
  and lower(u.email) = lower('terapis@example.com');

-- 3) Jadikan TERAPIS berdasarkan nama lengkap (hati-hati jika nama ganda)
-- update public.profiles
-- set role = 'therapist', updated_at = now()
-- where full_name = 'Dimas Pratama';

-- 4) Jadikan PASIEN (rehab)
-- update public.profiles p
-- set role = 'patient', updated_at = now()
-- from auth.users u
-- where u.id = p.id and lower(u.email) = lower('pasien@example.com');

-- 5) Kembalikan ke pengguna mandiri (workout)
-- update public.profiles p
-- set role = 'self', updated_at = now()
-- from auth.users u
-- where u.id = p.id and lower(u.email) = lower('user@example.com');

-- 6) Verifikasi hasil
-- select p.full_name, p.role, u.email
-- from public.profiles p join auth.users u on u.id = p.id
-- where lower(u.email) = lower('terapis@example.com');