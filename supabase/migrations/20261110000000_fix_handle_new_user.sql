-- ==============================================================================
-- FIX: sign up gagal dengan "Database error saving new user"
--
-- Penyebab: fungsi trigger public.handle_new_user() memakai tipe enum
-- `user_role` tanpa schema dan tanpa `SET search_path`. Saat trigger dipanggil
-- dari koneksi GoTrue (auth), search_path tidak selalu memuat schema public,
-- sehingga body fungsi gagal dikompilasi dan seluruh proses sign up dibatalkan.
--
-- Perbaikan: set search_path, tulis tipe secara lengkap (public.user_role),
-- validasi nilai role, buat idempotent, dan jangan blokir auth bila sinkronisasi
-- profil gagal.
-- ==============================================================================

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_role public.user_role := 'self';
    v_role_text TEXT;
BEGIN
    v_role_text := NULLIF(NEW.raw_user_meta_data->>'role', '');
    IF v_role_text IN ('self', 'patient', 'therapist') THEN
        v_role := v_role_text::public.user_role;
    END IF;

    INSERT INTO public.profiles (id, full_name, role)
    VALUES (
        NEW.id,
        COALESCE(NULLIF(NEW.raw_user_meta_data->>'full_name', ''), 'Pengguna Formly'),
        v_role
    )
    ON CONFLICT (id) DO NOTHING;

    INSERT INTO public.user_streaks (user_id, current_streak, longest_streak)
    VALUES (NEW.id, 0, 0)
    ON CONFLICT (user_id) DO NOTHING;

    RETURN NEW;
EXCEPTION
    WHEN OTHERS THEN
        RAISE WARNING 'handle_new_user gagal untuk %: %', NEW.id, SQLERRM;
        RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- Backfill profil & streak untuk user yang sudah terlanjur ada di auth.users
-- tetapi belum punya baris di public.profiles (akibat bug trigger sebelumnya).
INSERT INTO public.profiles (id, full_name, role)
SELECT
    u.id,
    COALESCE(
        NULLIF(u.raw_user_meta_data->>'full_name', ''),
        split_part(u.email, '@', 1),
        'Pengguna Formly'
    ),
    CASE
        WHEN u.raw_user_meta_data->>'role' IN ('self', 'patient', 'therapist')
            THEN (u.raw_user_meta_data->>'role')::public.user_role
        ELSE 'self'::public.user_role
    END
FROM auth.users u
ON CONFLICT (id) DO NOTHING;

INSERT INTO public.user_streaks (user_id, current_streak, longest_streak)
SELECT p.id, 0, 0
FROM public.profiles p
ON CONFLICT (user_id) DO NOTHING;
