-- ==============================================================================
-- FORMLY DATABASE SCHEMA & RLS POLICIES (Supabase Postgres)
-- Sesuai PRD Formly v0.4 (Bagian 8, 11, 12, 14)
-- ==============================================================================

-- 1. EXTENSIONS
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ==============================================================================
-- 2. ENUMS & DOMAINS
-- ==============================================================================
DO $$ BEGIN
    CREATE TYPE user_role AS ENUM ('patient', 'therapist', 'self');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE care_link_status AS ENUM ('pending', 'active', 'revoked');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE streak_day_status AS ENUM ('active', 'frozen', 'rest');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE message_sender AS ENUM ('user', 'ai');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- ==============================================================================
-- 3. CORE TABLES
-- ==============================================================================

-- PROFILES (terhubung langsung ke auth.users)
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    full_name TEXT NOT NULL DEFAULT '',
    role user_role NOT NULL DEFAULT 'self',
    voice_settings JSONB NOT NULL DEFAULT '{"volume": 70, "speech_rate": 50, "detailed": false, "silent": false}'::jsonb,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- JEMBATAN TERAPIS - PASIEN (Care Links dengan consent eksplisit)
CREATE TABLE IF NOT EXISTS public.care_links (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    therapist_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    patient_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    status care_link_status NOT NULL DEFAULT 'pending',
    consent_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE(therapist_id, patient_id)
);

-- KATALOG GERAKAN
CREATE TABLE IF NOT EXISTS public.exercises (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    difficulty TEXT NOT NULL,
    side TEXT NOT NULL,
    kind TEXT NOT NULL DEFAULT 'reps',
    icon TEXT NOT NULL,
    placement_guide TEXT NOT NULL,
    tips TEXT[] NOT NULL DEFAULT '{}',
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ATURAN GERAKAN & AMBANG SUDUT DETERMINISTIK (JSON Config)
CREATE TABLE IF NOT EXISTS public.exercise_rules (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    exercise_id TEXT NOT NULL REFERENCES public.exercises(id) ON DELETE CASCADE,
    version INT NOT NULL DEFAULT 1,
    rules_config JSONB NOT NULL DEFAULT '{}'::jsonb,
    error_cues JSONB NOT NULL DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE(exercise_id, version)
);

-- PROGRAM LATIHAN
CREATE TABLE IF NOT EXISTS public.programs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    owner_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    patient_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    title TEXT NOT NULL,
    schedule TEXT[] DEFAULT '{}',
    status TEXT NOT NULL DEFAULT 'active',
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- DETAIL ITEM PROGRAM
CREATE TABLE IF NOT EXISTS public.program_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    program_id UUID NOT NULL REFERENCES public.programs(id) ON DELETE CASCADE,
    exercise_id TEXT NOT NULL REFERENCES public.exercises(id) ON DELETE CASCADE,
    sets INT NOT NULL DEFAULT 3,
    reps INT NOT NULL DEFAULT 10,
    duration_seconds INT NOT NULL DEFAULT 0,
    sort_order INT NOT NULL DEFAULT 0,
    notes TEXT
);

-- SESI LATIHAN (TIDAK ADA FOTO ATAU VIDEO, HANYA ANGKA DAN SKOR)
CREATE TABLE IF NOT EXISTS public.sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    program_id UUID REFERENCES public.programs(id) ON DELETE SET NULL,
    exercise_id TEXT REFERENCES public.exercises(id) ON DELETE SET NULL,
    started_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    completed_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    avg_score INT NOT NULL DEFAULT 0,
    total_reps INT NOT NULL DEFAULT 0,
    duration_seconds INT NOT NULL DEFAULT 0,
    pain_before INT NOT NULL DEFAULT 0,
    pain_after INT,
    is_valid_session BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- SET DALAM SESI
CREATE TABLE IF NOT EXISTS public.session_sets (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    session_id UUID NOT NULL REFERENCES public.sessions(id) ON DELETE CASCADE,
    exercise_id TEXT NOT NULL REFERENCES public.exercises(id) ON DELETE CASCADE,
    set_number INT NOT NULL DEFAULT 1,
    reps_completed INT NOT NULL DEFAULT 0,
    score INT NOT NULL DEFAULT 0,
    errors_summary JSONB NOT NULL DEFAULT '[]'::jsonb
);

-- LOG EVENT REP (Opsional untuk evaluasi form detail)
CREATE TABLE IF NOT EXISTS public.rep_events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    session_id UUID NOT NULL REFERENCES public.sessions(id) ON DELETE CASCADE,
    set_number INT NOT NULL DEFAULT 1,
    rep_number INT NOT NULL,
    score INT NOT NULL,
    error_code TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- RINGKASAN AI DARI GROQ
CREATE TABLE IF NOT EXISTS public.ai_summaries (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    session_id UUID NOT NULL REFERENCES public.sessions(id) ON DELETE CASCADE,
    summary_text TEXT NOT NULL,
    tip_text TEXT,
    model TEXT NOT NULL DEFAULT 'llama-3.3-70b-versatile',
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- RIWAYAT CHAT PELATIH AI
CREATE TABLE IF NOT EXISTS public.chat_messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    sender message_sender NOT NULL DEFAULT 'user',
    message TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- CATATAN TERAPIS
CREATE TABLE IF NOT EXISTS public.therapist_notes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    therapist_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    patient_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    session_id UUID REFERENCES public.sessions(id) ON DELETE SET NULL,
    note TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- STREAK PENGGUNA (Gamifikasi Mode Workout)
CREATE TABLE IF NOT EXISTS public.user_streaks (
    user_id UUID PRIMARY KEY REFERENCES public.profiles(id) ON DELETE CASCADE,
    current_streak INT NOT NULL DEFAULT 0,
    longest_streak INT NOT NULL DEFAULT 0,
    last_active_date DATE,
    freezes_available INT NOT NULL DEFAULT 1,
    timezone TEXT NOT NULL DEFAULT 'Asia/Jakarta',
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- KALENDER HARI AKTIF STREAK
CREATE TABLE IF NOT EXISTS public.streak_days (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    activity_date DATE NOT NULL,
    status streak_day_status NOT NULL DEFAULT 'active',
    session_count INT NOT NULL DEFAULT 1,
    UNIQUE(user_id, activity_date)
);

-- TARGET MINGGUAN
CREATE TABLE IF NOT EXISTS public.weekly_goals (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    week_start DATE NOT NULL,
    target_days INT NOT NULL DEFAULT 5,
    achieved_days INT NOT NULL DEFAULT 0,
    UNIQUE(user_id, week_start)
);

-- XP & LEVELING
CREATE TABLE IF NOT EXISTS public.xp_events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    source TEXT NOT NULL,
    amount INT NOT NULL,
    session_id UUID REFERENCES public.sessions(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- BADGE
CREATE TABLE IF NOT EXISTS public.badges (
    id TEXT PRIMARY KEY,
    label TEXT NOT NULL,
    requirement JSONB NOT NULL DEFAULT '{}'::jsonb
);

-- BADGE PENGGUNA YANG DIRAIH
CREATE TABLE IF NOT EXISTS public.user_badges (
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    badge_id TEXT NOT NULL REFERENCES public.badges(id) ON DELETE CASCADE,
    unlocked_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    PRIMARY KEY(user_id, badge_id)
);

-- ==============================================================================
-- 4. ROW LEVEL SECURITY (RLS)
-- ==============================================================================
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.care_links ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.exercises ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.exercise_rules ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.programs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.program_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.session_sets ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.rep_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ai_summaries ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.chat_messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.therapist_notes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_streaks ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.streak_days ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.weekly_goals ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.xp_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.badges ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_badges ENABLE ROW LEVEL SECURITY;

-- 4.1 KATALOG (Bisa dibaca semua user terautentikasi dan anonim untuk demo)
DROP POLICY IF EXISTS "Katalog gerakan publik dibaca siapa saja" ON public.exercises;
CREATE POLICY "Katalog gerakan publik dibaca siapa saja" ON public.exercises
    FOR SELECT USING (true);

DROP POLICY IF EXISTS "Aturan gerakan publik dibaca siapa saja" ON public.exercise_rules;
CREATE POLICY "Aturan gerakan publik dibaca siapa saja" ON public.exercise_rules
    FOR SELECT USING (true);

DROP POLICY IF EXISTS "Katalog badge publik dibaca siapa saja" ON public.badges;
CREATE POLICY "Katalog badge publik dibaca siapa saja" ON public.badges
    FOR SELECT USING (true);

-- 4.2 PROFILES
DROP POLICY IF EXISTS "Pengguna membaca profil sendiri" ON public.profiles;
CREATE POLICY "Pengguna membaca profil sendiri" ON public.profiles
    FOR SELECT USING (auth.uid() = id);

DROP POLICY IF EXISTS "Pengguna memperbarui profil sendiri" ON public.profiles;
CREATE POLICY "Pengguna memperbarui profil sendiri" ON public.profiles
    FOR UPDATE USING (auth.uid() = id);

DROP POLICY IF EXISTS "Pengguna membuat profil sendiri" ON public.profiles;
CREATE POLICY "Pengguna membuat profil sendiri" ON public.profiles
    FOR INSERT WITH CHECK (auth.uid() = id);

-- Terapis dapat melihat profil pasien yang care_link-nya 'active'
DROP POLICY IF EXISTS "Terapis melihat profil pasien terhubung" ON public.profiles;
CREATE POLICY "Terapis melihat profil pasien terhubung" ON public.profiles
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.care_links cl
            WHERE cl.therapist_id = auth.uid()
              AND cl.patient_id = public.profiles.id
              AND cl.status = 'active'
        )
    );

-- 4.3 CARE LINKS
DROP POLICY IF EXISTS "Lihat care link milik sendiri (terapis atau pasien)" ON public.care_links;
CREATE POLICY "Lihat care link milik sendiri (terapis atau pasien)" ON public.care_links
    FOR SELECT USING (auth.uid() = therapist_id OR auth.uid() = patient_id);

DROP POLICY IF EXISTS "Terapis membuat undangan care link" ON public.care_links;
CREATE POLICY "Terapis membuat undangan care link" ON public.care_links
    FOR INSERT WITH CHECK (auth.uid() = therapist_id);

DROP POLICY IF EXISTS "Pasien atau terapis memperbarui status care link" ON public.care_links;
CREATE POLICY "Pasien atau terapis memperbarui status care link" ON public.care_links
    FOR UPDATE USING (auth.uid() = therapist_id OR auth.uid() = patient_id);

-- 4.4 SESI & SET LATIHAN
DROP POLICY IF EXISTS "Pengguna mengelola sesi sendiri" ON public.sessions;
CREATE POLICY "Pengguna mengelola sesi sendiri" ON public.sessions
    FOR ALL USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Terapis melihat sesi pasien terhubung" ON public.sessions;
CREATE POLICY "Terapis melihat sesi pasien terhubung" ON public.sessions
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.care_links cl
            WHERE cl.therapist_id = auth.uid()
              AND cl.patient_id = public.sessions.user_id
              AND cl.status = 'active'
        )
    );

DROP POLICY IF EXISTS "Pengguna mengelola set sesi sendiri" ON public.session_sets;
CREATE POLICY "Pengguna mengelola set sesi sendiri" ON public.session_sets
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM public.sessions s
            WHERE s.id = public.session_sets.session_id
              AND s.user_id = auth.uid()
        )
    );

DROP POLICY IF EXISTS "Terapis melihat set pasien terhubung" ON public.session_sets;
CREATE POLICY "Terapis melihat set pasien terhubung" ON public.session_sets
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.sessions s
            JOIN public.care_links cl ON cl.patient_id = s.user_id
            WHERE s.id = public.session_sets.session_id
              AND cl.therapist_id = auth.uid()
              AND cl.status = 'active'
        )
    );

DROP POLICY IF EXISTS "Pengguna mengelola rep event sendiri" ON public.rep_events;
CREATE POLICY "Pengguna mengelola rep event sendiri" ON public.rep_events
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM public.sessions s
            WHERE s.id = public.rep_events.session_id
              AND s.user_id = auth.uid()
        )
    );

-- 4.5 PROGRAM LATIHAN
DROP POLICY IF EXISTS "Pemilik atau pasien melihat program" ON public.programs;
CREATE POLICY "Pemilik atau pasien melihat program" ON public.programs
    FOR SELECT USING (auth.uid() = owner_id OR auth.uid() = patient_id);

DROP POLICY IF EXISTS "Terapis mengelola program" ON public.programs;
CREATE POLICY "Terapis mengelola program" ON public.programs
    FOR ALL USING (auth.uid() = owner_id);

DROP POLICY IF EXISTS "Lihat item program jika bisa akses program" ON public.program_items;
CREATE POLICY "Lihat item program jika bisa akses program" ON public.program_items
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.programs p
            WHERE p.id = public.program_items.program_id
              AND (p.owner_id = auth.uid() OR p.patient_id = auth.uid())
        )
    );

DROP POLICY IF EXISTS "Terapis mengelola item program" ON public.program_items;
CREATE POLICY "Terapis mengelola item program" ON public.program_items
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM public.programs p
            WHERE p.id = public.program_items.program_id
              AND p.owner_id = auth.uid()
        )
    );

-- 4.6 CHAT & AI SUMMARIES
DROP POLICY IF EXISTS "Pengguna membaca dan membuat chat sendiri" ON public.chat_messages;
CREATE POLICY "Pengguna membaca dan membuat chat sendiri" ON public.chat_messages
    FOR ALL USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Pengguna membaca ringkasan AI sesi sendiri" ON public.ai_summaries;
CREATE POLICY "Pengguna membaca ringkasan AI sesi sendiri" ON public.ai_summaries
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.sessions s
            WHERE s.id = public.ai_summaries.session_id
              AND s.user_id = auth.uid()
        )
    );

-- 4.7 STREAK, XP & BADGES
DROP POLICY IF EXISTS "Pengguna membaca streak sendiri" ON public.user_streaks;
CREATE POLICY "Pengguna membaca streak sendiri" ON public.user_streaks
    FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Pengguna mengelola streak sendiri" ON public.user_streaks;
CREATE POLICY "Pengguna mengelola streak sendiri" ON public.user_streaks
    FOR ALL USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Pengguna membaca kalender streak sendiri" ON public.streak_days;
CREATE POLICY "Pengguna membaca kalender streak sendiri" ON public.streak_days
    FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Pengguna membaca target mingguan sendiri" ON public.weekly_goals;
CREATE POLICY "Pengguna membaca target mingguan sendiri" ON public.weekly_goals
    FOR ALL USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Pengguna membaca riwayat XP sendiri" ON public.xp_events;
CREATE POLICY "Pengguna membaca riwayat XP sendiri" ON public.xp_events
    FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Pengguna membaca badge sendiri" ON public.user_badges;
CREATE POLICY "Pengguna membaca badge sendiri" ON public.user_badges
    FOR SELECT USING (auth.uid() = user_id);

-- 4.8 CATATAN TERAPIS
DROP POLICY IF EXISTS "Terapis dan pasien terkait membaca catatan" ON public.therapist_notes;
CREATE POLICY "Terapis dan pasien terkait membaca catatan" ON public.therapist_notes
    FOR SELECT USING (auth.uid() = therapist_id OR auth.uid() = patient_id);

DROP POLICY IF EXISTS "Terapis mengelola catatan" ON public.therapist_notes;
CREATE POLICY "Terapis mengelola catatan" ON public.therapist_notes
    FOR ALL USING (auth.uid() = therapist_id);

-- ==============================================================================
-- 5. TRIGGERS & FUNCTIONS
-- ==============================================================================

-- 5.1 Auto-create profile saat user sign up via Supabase Auth
-- Catatan: SET search_path wajib diisi. Tanpa ini, tipe `user_role` tidak
-- ter-resolve saat trigger dipanggil dari koneksi GoTrue (auth schema),
-- sehingga SETIAP sign up gagal dengan "Database error saving new user".
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

    -- Init user_streaks
    INSERT INTO public.user_streaks (user_id, current_streak, longest_streak)
    VALUES (NEW.id, 0, 0)
    ON CONFLICT (user_id) DO NOTHING;

    RETURN NEW;
EXCEPTION
    WHEN OTHERS THEN
        -- Jangan blokir pembuatan akun auth hanya karena sinkronisasi profil gagal.
        RAISE WARNING 'handle_new_user gagal untuk %: %', NEW.id, SQLERRM;
        RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- 5.2 Auto-update streak saat sesi valid selesai
CREATE OR REPLACE FUNCTION public.process_session_completion()
RETURNS TRIGGER AS $$
DECLARE
    session_date DATE;
    last_date DATE;
    streak_row public.user_streaks%ROWTYPE;
BEGIN
    IF NEW.is_valid_session IS NOT TRUE THEN
        RETURN NEW;
    END IF;

    session_date := (NEW.completed_at AT TIME ZONE 'Asia/Jakarta')::DATE;

    SELECT * INTO streak_row FROM public.user_streaks WHERE user_id = NEW.user_id FOR UPDATE;
    IF NOT FOUND THEN
        INSERT INTO public.user_streaks (user_id, current_streak, longest_streak, last_active_date)
        VALUES (NEW.user_id, 1, 1, session_date);
    ELSE
        last_date := streak_row.last_active_date;

        IF last_date IS NULL THEN
            UPDATE public.user_streaks
            SET current_streak = 1,
                longest_streak = GREATEST(longest_streak, 1),
                last_active_date = session_date,
                updated_at = now()
            WHERE user_id = NEW.user_id;
        ELSIF session_date = last_date THEN
            -- Sesi di hari yang sama: tidak menambah hitungan hari streak
            NULL;
        ELSIF session_date = last_date + INTERVAL '1 day' THEN
            -- Hari berurutan: tambah streak
            UPDATE public.user_streaks
            SET current_streak = current_streak + 1,
                longest_streak = GREATEST(longest_streak, current_streak + 1),
                last_active_date = session_date,
                updated_at = now()
            WHERE user_id = NEW.user_id;
        ELSE
            -- Streak putus, reset ke 1
            UPDATE public.user_streaks
            SET current_streak = 1,
                last_active_date = session_date,
                updated_at = now()
            WHERE user_id = NEW.user_id;
        END IF;
    END IF;

    -- Catat streak_days
    INSERT INTO public.streak_days (user_id, activity_date, status, session_count)
    VALUES (NEW.user_id, session_date, 'active', 1)
    ON CONFLICT (user_id, activity_date)
    DO UPDATE SET session_count = public.streak_days.session_count + 1;

    -- Berikan XP (+45 XP per sesi valid)
    INSERT INTO public.xp_events (user_id, source, amount, session_id)
    VALUES (NEW.user_id, 'sesi_latihan', 45, NEW.id);

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_session_completed ON public.sessions;
CREATE TRIGGER on_session_completed
    AFTER INSERT OR UPDATE ON public.sessions
    FOR EACH ROW
    WHEN (NEW.completed_at IS NOT NULL)
    EXECUTE FUNCTION public.process_session_completion();

-- ==============================================================================
-- 6. SEED DATA (Katalog Gerakan & Badge Awal)
-- ==============================================================================

INSERT INTO public.exercises (id, name, difficulty, side, kind, icon, placement_guide, tips) VALUES
('squat', 'Squat', 'Sedang', 'Samping', 'reps', 'squat', 'Taruh HP setinggi pinggang, 2-3 meter di samping badan.', ARRAY['Punggung tetap lurus', 'Lutut searah ujung kaki', 'Turun sampai paha sejajar lantai']),
('pushup', 'Push-up', 'Sedang', 'Samping', 'reps', 'pushup', 'Taruh HP di lantai, 2 meter di samping badan.', ARRAY['Badan lurus dari kepala ke tumit', 'Siku sekitar 45 derajat', 'Dada hampir menyentuh lantai']),
('plank', 'Plank', 'Mudah', 'Samping', 'timed', 'plank', 'Taruh HP di lantai, 2 meter di samping badan.', ARRAY['Pinggul jangan turun', 'Tarik perut ke dalam', 'Napas tetap teratur']),
('arm', 'Angkat Lengan', 'Mudah', 'Depan', 'reps', 'arm', 'Taruh HP setinggi dada, 2 meter di depan badan.', ARRAY['Bahu tetap rileks', 'Angkat perlahan', 'Siku sedikit ditekuk']),
('lunge', 'Lunge', 'Sulit', 'Samping', 'reps', 'lunge', 'Taruh HP setinggi pinggang, 3 meter di samping badan.', ARRAY['Lutut depan tidak melewati ujung kaki', 'Badan tegak', 'Langkah cukup lebar']),
('bridge', 'Glute Bridge', 'Mudah', 'Samping', 'reps', 'bridge', 'Taruh HP di lantai, 2 meter di samping badan.', ARRAY['Dorong lewat tumit', 'Tahan 2 detik di atas', 'Jangan melengkungkan punggung']),
('knee', 'Tekuk Lutut', 'Mudah', 'Samping', 'reps', 'knee', 'Taruh HP setinggi lutut, 2 meter di samping badan.', ARRAY['Gerak perlahan', 'Berhenti bila nyeri tajam', 'Paha tetap diam']),
('shoulder', 'Putar Bahu', 'Mudah', 'Depan', 'reps', 'shoulder', 'Taruh HP setinggi dada, 2 meter di depan badan.', ARRAY['Lingkaran kecil dulu', 'Leher rileks', 'Kedua sisi sama rata'])
ON CONFLICT (id) DO NOTHING;

INSERT INTO public.badges (id, label, requirement) VALUES
('s3', '3 Hari Beruntun', '{"streak": 3}'::jsonb),
('s7', '7 Hari Beruntun', '{"streak": 7}'::jsonb),
('s14', '14 Hari Beruntun', '{"streak": 14}'::jsonb),
('s30', '30 Hari Beruntun', '{"streak": 30}'::jsonb),
('s100', '100 Hari Beruntun', '{"streak": 100}'::jsonb),
('skor90', 'Skor 90+', '{"min_score": 90}'::jsonb),
('rep100', '100 Rep Pertama', '{"total_reps": 100}'::jsonb)
ON CONFLICT (id) DO NOTHING;
