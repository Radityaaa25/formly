-- ==============================================================================
-- Izinkan pengguna membuat/memperbaiki baris profilnya sendiri.
-- Diperlukan agar aplikasi bisa self-heal kalau baris profil belum terbentuk
-- (mis. user lama yang dibuat sebelum trigger handle_new_user diperbaiki).
-- ==============================================================================

DROP POLICY IF EXISTS "Pengguna membuat profil sendiri" ON public.profiles;
CREATE POLICY "Pengguna membuat profil sendiri" ON public.profiles
    FOR INSERT WITH CHECK (auth.uid() = id);

DROP POLICY IF EXISTS "Pengguna mengelola streak sendiri" ON public.user_streaks;
CREATE POLICY "Pengguna mengelola streak sendiri" ON public.user_streaks
    FOR ALL USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);
