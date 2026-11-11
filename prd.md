# PRD: Formly

Platform rehabilitasi dan latihan di rumah dengan AI kamera dan suara berbahasa Indonesia

Draf v0.4 · 7 November 2026 · Status: untuk review

## 1. Ringkasan Produk

Formly adalah aplikasi mobile (Flutter) yang menilai gerakan latihan lewat kamera HP, memandu pengguna dengan suara berbahasa Indonesia, dan menghubungkan pasien dengan terapis. Aplikasi punya dua mode:

- **Mode Rehab**: terapis membuat program, pasien mengerjakan di rumah, terapis memantau kepatuhan dan kualitas gerakan.
- **Mode Workout**: pengguna mandiri (gym dan olahraga umum) memilih gerakan, mendapat koreksi form, dan dimotivasi lewat sistem streak, XP, dan badge seperti di aplikasi belajar bahasa.

Pembagian peran teknologi: pose estimation on-device sebagai mata, aturan sudut deterministik sebagai penilai, Text-to-Speech sebagai suara pelatih, Groq (LLM dan Whisper) sebagai asisten penjelas dan perangkum, Supabase sebagai backend.

Tagline: "Kamera jadi mata, suara jadi pelatih, terapis tetap pengambil keputusan."

## 2. Latar Belakang dan Masalah

- Pasien pasca cedera atau operasi biasanya hanya mendapat beberapa sesi tatap muka, lalu berlatih sendiri di rumah tanpa pengawasan. Sulit memastikan gerakannya benar, dan salah gerak bisa menghambat pemulihan.
- Terapis tidak punya data objektif tentang seberapa rutin dan seberapa benar pasien berlatih di rumah.
- Saat HP disandarkan 2 sampai 3 meter dari badan, pasien tidak bisa melihat layar. Aplikasi yang hanya menampilkan angka di layar kurang praktis.
- Dari riset awal, banyak aplikasi rep counter berbasis kamera sudah ada (umumnya berbahasa Inggris dan tidak terhubung ke terapis), sedangkan platform fisioterapi digital seperti Kemtai berorientasi enterprise dan bersertifikasi medis. Celah untuk versi ringan, berbahasa Indonesia, dan menghubungkan terapis dengan pasien masih terlihat, namun perlu diverifikasi di Play Store Indonesia.

## 3. Tujuan dan Non-Tujuan

### Tujuan

1. Pasien dapat berlatih di rumah dengan koreksi gerakan real-time tanpa perlu melihat layar.
2. Terapis dapat membuat program, memantau kepatuhan, dan melihat kualitas gerakan pasien.
3. Seluruh pengalaman (teks, suara, chatbot) berbahasa Indonesia.
4. Video tidak pernah meninggalkan HP. Hanya data angka (sudut, skor, jumlah rep) yang disimpan.
5. Seluruh fitur inti bisa dijalankan dengan biaya nol untuk skala demo.
6. Pengguna Workout terdorong berlatih konsisten lewat streak dan gamifikasi, tanpa mendorong latihan berlebihan atau saat cedera.

### Non-tujuan

- Bukan alat medis dan tidak melakukan diagnosis.
- Tidak menilai beban atau kekuatan, hanya bentuk gerakan.
- Tidak menggantikan fisioterapis. Pasien dianjurkan memakai app di bawah arahan terapis.
- Tidak merekam atau menyimpan video.
- Tidak mengklaim sertifikasi medis atau kepatuhan regulasi tertentu pada tahap ini.

## 4. Pengguna dan Persona

| Peran | Contoh persona | Kebutuhan utama |
|---|---|---|
| Pasien | Bu Ratna, 58 tahun, pasca cedera lutut, kurang nyaman dengan layar kecil | Panduan jelas lewat suara, tahu gerakannya benar atau salah, pengingat latihan |
| Terapis | Dimas, 29 tahun, fisioterapis di klinik kecil | Buat program cepat, lihat kepatuhan dan skor pasien, tanpa sistem mahal |
| Pengguna Workout | Raka, 24 tahun, latihan di rumah | Hitung rep otomatis, koreksi form, catatan progres |
| Admin (roadmap) | Pengelola klinik | Kelola akun terapis dan data klinik |

## 5. Diferensiasi

1. **Jembatan terapis-pasien**: bukan sekadar rep counter. Terapis membuat program, pasien mengerjakan, terapis melihat hasilnya.
2. **Suara penuh dalam bahasa Indonesia**: hitung rep, koreksi, panduan sesi, dan kontrol perintah suara.
3. **Penjelasan kontekstual dari AI**: ringkasan sesi dalam bahasa sederhana, bukan hanya skor.
4. **Privasi**: video diproses di perangkat dan tidak disimpan.
5. **Gratis dan ringan** untuk klinik kecil dan pengguna individu.
6. **Streak dan gamifikasi untuk Workout**: kebiasaan latihan dibangun lewat streak harian, XP, badge, dan target mingguan, dengan penilaian form sebagai syarat sehingga yang dihargai adalah gerakan benar, bukan sekadar rajin membuka app.

Catatan: keunggulan nomor 4 dan 5 bukan pembeda tunggal karena aplikasi lain juga memproses on-device. Kekuatan utama ada pada kombinasi nomor 1, 2, dan 3.

## 6. Ruang Lingkup

### MVP (wajib untuk demo)

- Login dan peran (pasien, terapis, pengguna workout).
- Katalog 4 gerakan dengan penilaian form dan hitung rep.
- Sesi latihan berkamera dengan feedback suara dan perintah suara dasar.
- Pengecekan sebelum sesi (cahaya, posisi, jarak) dan pemantauan kualitas deteksi selama sesi.
- Program latihan (CRUD oleh terapis), log sesi, riwayat dan grafik progres.
- Ringkasan sesi dan chatbot pelatih (Groq).
- Streak harian dan kalender hari aktif untuk Mode Workout (XP, badge, streak freeze, dan pengingat masuk P1).
- Dashboard terapis sederhana di dalam app: daftar pasien, kepatuhan, skor.

### Versi berikutnya

- Generator draf program berbasis AI (ditinjau terapis sebelum aktif).
- Pengingat terjadwal (FCM) dan target mingguan.
- Leaderboard komunitas (opt-in) dan tantangan mingguan.
- Mode offline penuh dengan sinkronisasi.
- Dashboard web untuk klinik.
- Gerakan tambahan (lunge, push-up, bicep curl, shoulder press).
- Safety Mode (deteksi benturan) sebagai modul opsional.

### Di luar lingkup

- Integrasi rekam medis resmi (SATUSEHAT), pembayaran, telekonsultasi video.
- Penilaian gerakan berbaring dengan alat besar yang menutupi badan.
- Wearable dan smartwatch.

## 7. Alur Pengguna Utama

### Alur A: Pasien mengerjakan program

1. Pasien membuka app dan melihat program hari ini dari terapis.
2. Memilih gerakan, app menampilkan petunjuk penempatan HP (jarak, tinggi, sisi badan).
3. App menjalankan pengecekan sebelum sesi (cahaya, posisi, jarak, seluruh badan terlihat, lihat 9.3). Jika ada yang belum sesuai, suara memberi arahan.
4. Hitung mundur lewat suara, sesi dimulai.
5. Selama gerakan: rep dihitung lewat suara, koreksi singkat diucapkan di akhir rep.
6. Setelah set selesai, istirahat dengan timer suara. Pasien bisa berkata "jeda", "lanjut", atau "berhenti".
7. Sesi selesai: ringkasan skor tampil dan dibacakan. Data tersimpan dan terkirim ke terapis.

### Alur B: Terapis membuat dan memantau program

1. Terapis menambahkan pasien lewat kode undangan, pasien menyetujui akses (consent).
2. Terapis membuat program: pilih gerakan, set, rep, hari, catatan.
3. Terapis melihat kepatuhan mingguan, skor form rata-rata, dan kesalahan yang sering muncul.
4. Terapis mengubah program berdasarkan data. Perubahan langsung terlihat oleh pasien.

### Alur C: Pengguna Workout mandiri

1. Pilih gerakan atau rutinitas buatan sendiri.
2. Latihan dengan feedback suara dan hitung rep.
3. Sesi valid pertama hari itu menambah streak: layar perayaan singkat tampil dan suara menyebut jumlah hari beruntun.
4. Lihat progres, XP, badge, dan tanya chatbot pelatih.
5. Jika belum latihan menjelang malam, pengguna menerima pengingat streak.

## 8. Kebutuhan Fungsional

Prioritas: P0 wajib MVP, P1 sebaiknya ada, P2 nanti.

### 8.1 Akun dan peran

- FR-01 (P0): Registrasi dan login dengan email (Supabase Auth). Pilih peran saat daftar.
- FR-02 (P0): Terapis menghubungkan pasien lewat kode undangan. Pasien harus menyetujui sebelum terapis melihat data.
- FR-03 (P0): Pasien dapat mencabut akses terapis kapan saja.
- FR-04 (P1): Pasien dapat menghapus akun dan seluruh datanya.

### 8.2 Program dan katalog (CRUD)

- FR-05 (P0): Katalog gerakan (baca): nama, deskripsi, petunjuk penempatan kamera, video/ilustrasi contoh.
- FR-06 (P0): Terapis membuat, membaca, mengubah, dan menghapus program untuk pasien: daftar gerakan, set, rep (atau durasi), hari.
- FR-07 (P0): Pengguna Workout membuat, mengubah, dan menghapus rutinitas sendiri.
- FR-08 (P1): Template program yang bisa disalin ke beberapa pasien.
- FR-09 (P1): Catatan terapis per pasien dan per sesi.
- FR-10 (P0): Pasien melihat dan mengedit catatan nyeri harian (skala 0 sampai 10) sebelum dan sesudah sesi.

### 8.3 Sesi latihan berkamera

- FR-11 (P0): Pratinjau kamera dengan overlay kerangka tubuh.
- FR-12 (P0): Pengecekan kelayakan sebelum sesi dimulai, detailnya di FR-44 sampai FR-48 dan bagian 9.3.
- FR-13 (P0): Hitung rep otomatis lewat state machine sudut sendi.
- FR-14 (P0): Penilaian form per rep: skor 0 sampai 100 dan daftar kesalahan.
- FR-15 (P0): Gerakan statis (plank) memakai timer dan penilaian postur selama durasi.
- FR-16 (P0): Tombol berhenti darurat di layar dan lewat suara. Sesi berhenti seketika.
- FR-17 (P1): Penyimpanan hasil sesi saat offline dan sinkron saat online.
- FR-44 (P0): Pengecekan sebelum sesi: cahaya, HP tegak dan stabil, seluruh badan terlihat, jarak, sisi kamera sesuai gerakan, dan stabilitas deteksi.
- FR-45 (P0): Hasil pengecekan diucapkan lewat suara (pengguna tidak melihat layar) dan ditampilkan sebagai daftar centang.
- FR-46 (P1): Opsi Tetap mulai dengan peringatan akurasi rendah. Sesi seperti ini ditandai kualitas rendah.
- FR-47 (P0): Pemantauan kualitas selama sesi: hitung rep dan koreksi dijeda saat deteksi tidak andal.
- FR-48 (P1): Layar petunjuk menampilkan tips pemasangan kamera dan pakaian serta catatan keterbatasan akurasi.

### 8.4 Suara

- FR-18 (P0): Hitung rep, koreksi, dan panduan sesi diucapkan lewat TTS on-device.
- FR-19 (P0): Perintah suara: mulai, jeda, lanjut, ulangi, selesai, berhenti.
- FR-20 (P0): Mikrofon dinonaktifkan sesaat saat TTS berbicara agar tidak salah menangkap suara sendiri.
- FR-21 (P1): Pengaturan: volume, kecepatan bicara, tingkat detail koreksi (ringkas atau lengkap), mode tanpa suara.
- FR-22 (P1): Pertanyaan bebas lewat suara (rekam, Whisper via Edge Function) dijawab chatbot.

### 8.5 AI Groq

- FR-23 (P0): Ringkasan sesi dalam bahasa Indonesia sederhana (maksimal 3 kalimat plus 1 saran), dibuat dari data angka sesi.
- FR-24 (P0): Chatbot pelatih untuk pertanyaan teknik gerakan dan edukasi umum, dengan guardrail keselamatan.
- FR-25 (P1): Ringkasan mingguan untuk terapis per pasien.
- FR-26 (P2): Generator draf program, wajib disetujui terapis sebelum aktif.

### 8.6 Progres dan pemantauan

- FR-27 (P0): Riwayat sesi dan grafik skor form, volume rep, dan kepatuhan per minggu.
- FR-28 (P0): Terapis melihat daftar pasien dengan indikator kepatuhan dan peringatan pasien yang tidak berlatih beberapa hari.
- FR-29 (P1): Target mingguan dan progres per minggu (detail streak ada di 8.7).
- FR-30 (P1): Pengingat latihan lewat notifikasi push.

### 8.7 Streak dan gamifikasi (Mode Workout)

Berlaku untuk Mode Workout (gym dan olahraga umum). Mode Rehab tidak memakai streak yang menekan. Sebagai gantinya, Rehab memakai indikator kepatuhan sesuai jadwal program terapis (FR-27 dan FR-28), karena pasien cedera tidak boleh terdorong berlatih demi mempertahankan angka.

- FR-31 (P0): Streak harian bertambah 1 untuk setiap hari kalender (zona waktu pengguna, default WIB) yang memiliki minimal satu sesi valid.
- FR-32 (P0): Definisi sesi valid: minimal satu set dengan rep yang terdeteksi dan dinilai oleh mesin gerakan (bukan input manual), dengan total minimal sekitar 10 rep valid atau 5 menit aktif. Nilai awal ini dapat dikonfigurasi.
- FR-33 (P0): Halaman utama menampilkan jumlah hari beruntun, rekor terpanjang, dan kalender hari aktif (mingguan dan bulanan).
- FR-34 (P1): Pengingat lewat notifikasi push: ajakan latihan di jam pilihan pengguna dan peringatan saat streak hampir putus. Dapat dimatikan, maksimal 1 sampai 2 notifikasi per hari.
- FR-35 (P1): Streak Freeze: pelindung yang otomatis terpakai saat satu hari terlewat (misalnya 1 per minggu, atau didapat dari XP) agar hari sakit atau libur tidak memutus streak.
- FR-36 (P1): Hari istirahat terjadwal: pengguna menandai hari istirahat di rutinitasnya dan hari tersebut tidak memutus streak.
- FR-37 (P1): Target mingguan (misalnya 3 sampai 5 hari) dengan indikator progres, serta streak mingguan sebagai alternatif bagi pengguna yang tidak berlatih setiap hari.
- FR-38 (P1): XP dan level. XP diperoleh dari sesi valid, jumlah rep, skor form tinggi, dan target yang tercapai. Skor form ikut menentukan XP agar kualitas gerakan dihargai, bukan hanya jumlah.
- FR-39 (P1): Badge dan milestone: streak 3, 7, 14, 30, dan 100 hari, rep kumulatif, skor form 90 ke atas, dan gerakan pertama dicoba. Perayaan singkat di layar dan diucapkan lewat suara.
- FR-40 (P1): Ringkasan sesi dan pelatih suara menyebut progres streak, misalnya hari ke berapa berturut-turut, memakai data angka dari server.
- FR-41 (P1): Pemulihan streak sekali (repair) dengan syarat tertentu, misalnya menyelesaikan sesi ganda pada hari berikutnya.
- FR-42 (P2): Leaderboard teman atau komunitas dan tantangan mingguan, hanya untuk pengguna yang memilih ikut (opt-in).
- FR-43 (P2): Berbagi kartu pencapaian berupa gambar tanpa data sensitif.

Prinsip desain dan guardrail:

- **Jangan mendorong latihan saat cedera.** Jika pengguna melaporkan nyeri tinggi atau gejala berbahaya, app menyarankan istirahat dan memberi freeze tanpa penalti.
- **Anti-curang.** Hanya sesi dengan rep yang terdeteksi mesin gerakan dengan confidence memadai yang dihitung. Ada batas XP harian. Streak dihitung di server, bukan di klien.
- **Zona waktu dan offline.** Pergantian hari mengikuti zona waktu profil (pukul 00:00 lokal). Sesi offline disinkronkan dengan timestamp lokal agar streak tidak putus karena sinkronisasi terlambat. Server menghitung ulang dan menjadi sumber kebenaran.
- **Perhitungan streak** memakai fungsi database yang dipicu saat sesi valid tersimpan, ditambah tugas terjadwal harian (pg_cron atau Edge Function terjadwal) untuk memproses hari yang terlewat dan menerapkan freeze.
- **Orisinal.** Mekanik terinspirasi aplikasi lain, tetapi nama, maskot, dan aset visual dibuat sendiri.
- **Tidak berlebihan.** Hindari notifikasi yang menekan atau bernada menghukum. Gunakan bahasa yang mendukung.

## 9. Mesin Penilaian Gerakan

### 9.1 Alur pemrosesan

1. Paket `camera` menangkap frame, `google_mlkit_pose_detection` mengeluarkan 33 landmark tubuh (koordinat dan tingkat keyakinan).
2. Smoothing: rata-rata bergerak beberapa frame untuk mengurangi getaran titik.
3. Hitung sudut sendi dengan trigonometri dari tiga titik.
4. State machine memutuskan fase gerakan (turun, bawah, naik, atas) dan menghitung rep.
5. Aturan per gerakan menilai form dan menghasilkan kode kesalahan.
6. Kode kesalahan dipetakan ke kalimat suara pendek.
7. Hasil per rep dan per sesi disimpan lokal lalu disinkronkan.

Semua penilaian dilakukan kode deterministik, bukan LLM, supaya cepat, konsisten, dan bisa divalidasi terapis.

### 9.2 Gerakan MVP dan aturan awal

Nilai ambang di bawah adalah titik awal untuk diuji dan wajib divalidasi oleh fisioterapis sebelum dipakai ke pasien.

| Gerakan | Sisi kamera | Sudut utama | Aturan awal | Kesalahan yang dideteksi |
|---|---|---|---|---|
| Squat tanpa beban | Samping | Pinggul-lutut-pergelangan | Rep valid jika sudut lutut turun di bawah sekitar 100° lalu kembali di atas sekitar 160° | Kurang dalam, badan terlalu condong ke depan, lutut melewati jari kaki terlalu jauh |
| Fleksi lutut berdiri | Samping | Pinggul-lutut-pergelangan | Rep valid jika sudut lutut mencapai target program lalu kembali lurus | Gerak kurang jauh, pinggul ikut bergerak |
| Angkat lengan ke samping | Depan | Pinggul-bahu-siku | Rep valid jika lengan naik ke target (misal sekitar 90°) lalu turun | Bahu terangkat, lengan tidak simetris, kurang tinggi |
| Plank (statis) | Samping | Bahu-pinggul-pergelangan kaki | Selaras jika sudut badan mendekati lurus selama durasi | Pinggul turun, pinggul terlalu naik |

Setiap gerakan disimpan sebagai konfigurasi (JSON) di tabel `exercise_rules`, sehingga ambang bisa disesuaikan tanpa mengubah kode.

### 9.3 Pengecekan sebelum sesi

Sebelum setiap sesi, app menjalankan pengecekan otomatis selama beberapa detik. Hasilnya dibacakan lewat suara dan ditampilkan sebagai daftar centang.

| Pengecekan | Cara | Contoh arahan suara |
|---|---|---|
| Cahaya | Rata-rata kecerahan frame kamera, dan deteksi kontra cahaya (latar jauh lebih terang dari tubuh) | "Cahaya kurang, cari tempat lebih terang" atau "Jangan membelakangi jendela" |
| HP tegak dan stabil | Akselerometer: kemiringan mendekati tegak dan getaran rendah | "Sandarkan HP dengan stabil" |
| Seluruh badan terlihat | Landmark kepala, bahu, pinggul, lutut, dan pergelangan kaki berada di dalam frame dengan confidence cukup | "Mundur sedikit, seluruh badan harus terlihat" |
| Jarak | Tinggi tubuh di frame sekitar 60 sampai 90 persen tinggi layar | "Mundur sedikit" atau "Maju sedikit" |
| Sisi kamera sesuai gerakan | Rasio lebar bahu terhadap tinggi badan: sempit untuk tampak samping, lebar untuk tampak depan | "Berdiri menyamping ke kamera" |
| Stabilitas deteksi | Confidence rata-rata di atas batas selama sekitar 2 sampai 3 detik berturut-turut | "Siap, mulai dalam tiga" |

Aturan:

- Sesi dimulai otomatis hanya bila semua pengecekan lolos. Pengguna bisa memilih Tetap mulai (tombol atau perintah suara) dengan peringatan bahwa akurasi bisa rendah.
- Sesi yang dimulai dengan Tetap mulai, atau yang kualitas deteksinya rendah, ditandai kualitas rendah: diberi tahu ke pengguna, tidak dihitung untuk streak dan XP, dan ditandai di dashboard terapis.
- Pengecekan tidak bisa menilai pakaian longgar atau pakaian yang warnanya menyatu dengan latar. Hal ini hanya diingatkan lewat tips di layar petunjuk (pakai pakaian yang pas di badan dan kontras dengan latar).
- ML Kit Pose Detection melacak satu orang (yang paling menonjol), sehingga app tidak dapat mendeteksi orang kedua di frame. Pengguna diingatkan memastikan hanya dirinya yang berada di depan kamera.

Pemantauan selama sesi:

- Jika confidence landmark yang dibutuhkan turun di bawah batas lebih dari sekitar 1 detik, hitung rep dan koreksi dijeda, suara memberi tahu sekali (Posisi kurang terlihat), dan sesi lanjut otomatis setelah kembali normal.
- Rep yang terjadi saat deteksi tidak andal tidak dihitung.

### 9.4 Catatan akurasi dan keterbatasan

- Kamera 2D sulit membaca kedalaman dan rotasi. Penilaian lebih andal untuk sudut sendi besar dari sisi yang tepat (misalnya lutut saat squat dari samping) dibanding pergeseran halus (misalnya lutut masuk ke dalam dari depan).
- Selisih sudut kecil (sekitar 5 sampai 10 derajat) tidak dijadikan dasar koreksi. Ambang diberi margin.
- Tiga status penilaian: benar, salah jelas, dan ragu. Pada status ragu app tidak mengoreksi. Hanya kesalahan besar dan konsisten yang dikoreksi.
- Akurasi turun pada anggota badan yang tertutup, pakaian longgar, cahaya buruk, jarak jauh, dan gerakan cepat.
- Akurasi nyata diukur lewat pengujian: sekitar 20 sampai 30 video dari beberapa orang, dilabeli benar atau salah per rep oleh 1 sampai 2 penilai (idealnya fisioterapis), lalu dibandingkan dengan hasil app (akurasi hitung rep, precision, dan recall deteksi kesalahan).
- Catatan untuk pengguna di layar petunjuk dan Profil: Formly membantu mendeteksi kesalahan gerakan yang jelas bila kamera dipasang sesuai anjuran. Bukan alat ukur presisi dan bukan pengganti fisioterapis.

## 10. Spesifikasi Suara

### 10.1 Suara keluar (TTS)

- Mesin: `flutter_tts` dengan locale `id-ID`, berjalan di perangkat tanpa internet.
- Kalimat pendek, maksimal 5 sampai 6 kata. Contoh: "Turun sedikit lagi", "Punggung tegak", "Bagus, tiga".
- Aturan anti-spam: maksimal satu koreksi per rep, diucapkan di akhir rep (bukan di tengah gerakan), jeda minimal beberapa detik antar koreksi, dan prioritaskan kesalahan yang paling sering atau paling penting.
- Hitungan rep selalu diucapkan lebih dulu dari koreksi.
- Jika TTS id-ID tidak tersedia di perangkat, app menampilkan peringatan dan beralih ke teks plus bunyi sederhana.

### 10.2 Suara masuk

- Perintah pendek: `speech_to_text` (pengenal bawaan HP) untuk respons cepat.
- Pertanyaan bebas: rekam singkat lalu kirim ke Edge Function yang memanggil Whisper (Groq). Audio tidak disimpan, hanya teks transkrip yang dipakai.
- Mikrofon nonaktif saat TTS bicara. Alternatif tombol tekan-untuk-bicara.
- Setiap perintah suara punya padanan tombol di layar sebagai cadangan.
- Izin mikrofon diminta dengan penjelasan jelas.

## 11. Spesifikasi AI (Groq)

App tidak pernah memanggil Groq langsung. Semua lewat Supabase Edge Functions agar API key aman, ada rate limit per pengguna, dan hasil bisa di-cache.

| Fitur | Input | Output | Catatan |
|---|---|---|---|
| Ringkasan sesi | Data angka sesi (rep, skor, kode kesalahan) | 3 kalimat plus 1 saran | Model kecil, cache per sesi |
| Chatbot pelatih | Pertanyaan pengguna, konteks program | Jawaban singkat bahasa Indonesia | Guardrail keselamatan wajib |
| Transkripsi | Audio pendek | Teks | Whisper, audio tidak disimpan |
| Ringkasan mingguan terapis | Data seminggu per pasien | Poin utama dan pasien perlu perhatian | Hanya dilihat terapis terkait |
| Draf program (P2) | Tujuan, level, hari | Draf program terstruktur | Wajib disetujui terapis |

### Guardrail

- AI tidak mendiagnosis, tidak meresepkan, dan tidak mengubah program tanpa persetujuan terapis.
- Jika pengguna menyebut gejala berbahaya (nyeri dada, sesak, pingsan, nyeri tajam mendadak, mati rasa), AI menyarankan berhenti dan menghubungi tenaga kesehatan atau layanan darurat, bukan memberi saran latihan.
- Jawaban memakai data yang dikirim, tidak mengarang angka sesi.
- Nama model Groq disimpan sebagai konfigurasi, karena daftar model bisa berubah.
- Free tier memiliki batas. Pakai model kecil, cache, dan batas permintaan per pengguna.

## 12. Model Data (Supabase Postgres)

| Tabel | Isi utama |
|---|---|
| profiles | id, nama, peran (patient, therapist, self), pengaturan suara |
| care_links | therapist_id, patient_id, status (pending, active, revoked), consent_at |
| exercises | id, nama, deskripsi, petunjuk kamera, tipe (reps atau timed) |
| exercise_rules | exercise_id, versi, konfigurasi sudut dan ambang (JSON), pemetaan kesalahan ke kalimat |
| programs | id, pemilik, untuk pasien, judul, jadwal, status |
| program_items | program_id, exercise_id, set, rep atau durasi, urutan, catatan |
| sessions | id, user_id, program_id, mulai, selesai, skor rata-rata, nyeri sebelum dan sesudah |
| session_sets | session_id, exercise_id, rep selesai, skor, daftar kesalahan |
| rep_events (opsional) | set_id, nomor rep, skor, kode kesalahan |
| ai_summaries | session_id atau minggu, teks, model, dibuat pada |
| chat_messages | user_id, peran, teks, dibuat pada |
| therapist_notes | therapist_id, patient_id, session_id, teks |
| notifications | user_id, jenis, jadwal, status |
| user_streaks | user_id, streak_saat_ini, rekor, tanggal_aktif_terakhir, freeze_tersedia, zona_waktu |
| streak_days | user_id, tanggal, status (active, frozen, rest), jumlah_sesi |
| weekly_goals | user_id, minggu, target_hari, hari_tercapai |
| xp_events | user_id, sumber, jumlah, session_id, dibuat pada |
| badges | id, kode, nama, syarat (JSON) |
| user_badges | user_id, badge_id, diraih pada |

Aturan RLS inti:

- Pengguna hanya membaca dan mengubah data miliknya.
- Terapis hanya membaca data pasien yang punya `care_links` berstatus active.
- Pencabutan akses oleh pasien langsung memutus akses terapis.
- Tabel katalog (`exercises`, `exercise_rules`, `badges`) bisa dibaca semua pengguna login, hanya admin yang boleh mengubah.
- Tabel streak dan XP hanya bisa diubah lewat fungsi server, bukan langsung dari klien, untuk mencegah kecurangan. Leaderboard hanya memakai data pengguna yang opt-in.

Tidak ada tabel atau bucket untuk video. Foto tidak disimpan.

## 13. Arsitektur dan Tech Stack

| Lapisan | Teknologi |
|---|---|
| Mobile | Flutter (Android sebagai target utama, iOS menyusul) |
| Pose estimation | `google_mlkit_pose_detection` + `camera`, on-device |
| Suara | `flutter_tts`, `speech_to_text`, `record` (untuk Whisper) |
| State dan lokal | Riverpod atau Bloc, `drift` untuk antrean offline |
| Backend | Supabase: Postgres, Auth, RLS, Realtime, Edge Functions |
| AI | Groq lewat Edge Function (LLM tool calling dan Whisper) |
| Notifikasi | Firebase Cloud Messaging |
| Grafik | `fl_chart` |

Catatan teknis:

- Pose detection ML Kit hanya untuk Android dan iOS, tidak jalan di Flutter web. Dashboard web untuk terapis, jika dibuat, memakai data dari Supabase saja.
- Pemrosesan frame berjalan di isolate atau thread terpisah agar UI tetap lancar.
- Edge Functions: `summarize-session`, `coach-chat`, `transcribe-audio`, `weekly-summary`. Semua memeriksa JWT pengguna dan menerapkan rate limit.
- Streak, XP, dan badge dihitung di sisi server (fungsi database dan tugas terjadwal), lihat 8.7.

## 14. Privasi dan Keamanan

- Video dan frame kamera diproses di memori dan dibuang. Tidak ada yang diunggah.
- Data yang disimpan hanya angka hasil sesi, catatan nyeri, dan teks chat.
- Consent eksplisit sebelum terapis melihat data pasien, dan dapat dicabut kapan saja.
- Komunikasi lewat HTTPS. Pengaturan RLS aktif sejak awal pada semua tabel.
- Kunci API (Groq, service role Supabase) hanya berada di Edge Function, tidak di aplikasi.
- Audio suara tidak disimpan setelah transkripsi.
- Desain mengikuti prinsip pelindungan data pribadi (minimisasi data, persetujuan, hak hapus), namun belum mengklaim sertifikasi atau kepatuhan formal terhadap UU PDP.
- Demo memakai data sintetis.
- Klaim produk: alat bantu latihan di bawah arahan terapis, bukan alat medis.

## 15. Kebutuhan Non-Fungsional

- **Latensi feedback**: koreksi terucap kurang dari sekitar 500 ms setelah rep selesai (target, diukur di perangkat uji).
- **Frame rate**: pemrosesan pose minimal sekitar 15 fps pada HP kelas menengah.
- **Offline**: sesi latihan berjalan tanpa internet. AI chat dan ringkasan membutuhkan koneksi, dengan fallback ringkasan sederhana dari aturan lokal.
- **Baterai dan panas**: sesi 10 sampai 15 menit tidak membuat HP terlalu panas. Pantau dan batasi resolusi kamera bila perlu.
- **Aksesibilitas**: ukuran teks besar, kontras tinggi, dan seluruh alur sesi bisa dijalankan dengan suara.
- **Biaya**: dapat dijalankan penuh di free tier Supabase dan Groq untuk skala demo.
- **Perangkat**: Android 8 ke atas (sesuaikan dengan syarat paket ML Kit), uji pada setidaknya tiga tipe HP.

## 16. Metrik Keberhasilan

Target awal untuk MVP, bukan klaim klinis:

| Metrik | Target |
|---|---|
| Akurasi hitung rep (dibanding hitung manual, 4 gerakan, minimal 20 sesi uji) | 90% atau lebih |
| Kesesuaian deteksi kesalahan form dengan penilaian fisioterapis pada sampel rekaman uji | Dicatat dan diperbaiki iteratif, target awal 80% |
| Waktu dari buka app ke mulai sesi | Kurang dari 1 menit |
| Sesi yang lolos pengecekan awal pada percobaan pertama (uji pengguna) | 70% atau lebih (target awal) |
| Sesi yang selesai tanpa harus menyentuh layar | 80% atau lebih dalam uji pengguna |
| Waktu terapis membuat program 3 gerakan | Kurang dari 2 menit |
| Kepuasan pengguna uji (skala 1 sampai 5) | 4 atau lebih |
| Pengguna Workout yang mencapai streak 3 hari dalam 7 hari pertama | 40% atau lebih (target awal) |
| Retensi hari ke-7 pengguna Workout | Dicatat sebagai baseline, target awal 25% |

## 17. Risiko dan Mitigasi

| Risiko | Dampak | Mitigasi |
|---|---|---|
| Akurasi pose turun (cahaya, pakaian longgar, sudut kamera) | Rep salah hitung, koreksi keliru | Pengecekan kelayakan posisi, confidence gating, smoothing, panduan penempatan HP |
| Koreksi salah menyebabkan pengguna melakukan gerakan keliru | Cedera atau hilang kepercayaan | Ambang divalidasi terapis, disclaimer jelas, tombol berhenti, koreksi konservatif |
| Suara terlalu cerewet atau salah tangkap perintah | Pengalaman buruk | Aturan anti-spam, mikrofon dimatikan saat TTS, tombol cadangan |
| TTS bahasa Indonesia tidak tersedia di sebagian HP | Fitur suara tidak jalan | Cek saat onboarding, fallback teks, uji di perangkat demo |
| ML Kit hanya melacak satu orang | Orang lain di frame bisa mengganggu hasil | Instruksi dan tips pemasangan, pengecekan stabilitas deteksi, pertimbangkan MediaPipe bila perlu multi-orang |
| Batas free tier Groq | AI lambat atau gagal | Model kecil, cache, rate limit, fallback ringkasan lokal |
| Klaim medis berlebihan | Risiko etika dan hukum | Posisi sebagai alat bantu, wording disclaimer, tidak mendiagnosis |
| Ruang lingkup terlalu besar | Tidak selesai | Pegang daftar MVP, gerakan dibatasi 4, mock fitur P2 |
| Banyak pesaing rep counter gratis | Tidak menonjol | Fokus pada jembatan terapis-pasien dan suara Indonesia |
| Streak mendorong latihan berlebihan atau saat cedera | Cedera, kelelahan | Streak freeze, hari istirahat, peringatan saat nyeri tinggi, XP berdasarkan kualitas form |
| Kecurangan streak (gerakan palsu, mengubah jam HP) | Data tidak adil | Hanya sesi dengan rep terdeteksi mesin, perhitungan di server, batas XP harian |
| Notifikasi terlalu sering | Pengguna mematikan notifikasi atau berhenti memakai app | Maksimal 1 sampai 2 per hari, jam bisa diatur, nada mendukung |

## 18. Rencana Pengerjaan

Deadline belum ditentukan, jadi rencana berikut berbasis fase dan perlu disesuaikan.

1. **Fase 1, fondasi**: setup Flutter dan Supabase, Auth, peran, skema dan RLS, katalog gerakan.
2. **Fase 2, mesin gerakan**: kamera, ML Kit, perhitungan sudut, state machine rep, aturan squat sebagai gerakan pertama, lalu tiga gerakan lain.
3. **Fase 3, suara**: TTS, aturan anti-spam, perintah suara, tombol berhenti.
4. **Fase 4, program dan data**: CRUD program, log sesi, riwayat, grafik, dashboard terapis, consent, dan streak dasar (P0). XP, badge, freeze, dan pengingat (P1) menyusul jika waktu cukup.
5. **Fase 5, AI**: Edge Functions Groq, ringkasan sesi, chatbot dengan guardrail, Whisper untuk pertanyaan suara.
6. **Fase 6, uji dan poles**: uji akurasi dengan relawan, validasi ambang dengan fisioterapis, perbaikan UX, data sintetis dan skenario demo.

Jalur kritis: mesin gerakan dan suara. Kerjakan dua hal ini lebih dulu karena paling berisiko secara teknis.

## 19. Skenario Demo (3 sampai 4 menit)

1. Terapis membuat program 3 gerakan untuk pasien dalam hitungan detik.
2. Pasien membuka app dan HP disandarkan. Suara menuntun posisi dan memulai hitungan mundur.
3. Pasien melakukan squat. Rep dihitung lewat suara, lalu muncul koreksi: "Turun sedikit lagi".
4. Pasien berkata "jeda", app berhenti sejenak, lalu "lanjut".
5. Sesi selesai, ringkasan dibacakan: skor, kesalahan paling sering, dan saran singkat.
6. Pasien bertanya lewat suara tentang teknik. Chatbot menjawab dalam bahasa Indonesia.
7. Terapis melihat dashboard: kepatuhan, skor, dan ringkasan mingguan otomatis.
8. (Opsional) Beralih ke Mode Workout: satu sesi singkat menambah streak, layar perayaan muncul, dan suara menyebut hari ke berapa berturut-turut.

## 20. Pertanyaan Terbuka

- Nama final produk dan identitas visual?
- Ini untuk lomba atau produk jangka panjang? Jika lomba, apa kriteria juri dan berapa batas waktunya?
- Berapa orang di tim dan siapa yang berpengalaman dengan Flutter dan ML on-device?
- Apakah ada akses ke fisioterapis untuk validasi ambang gerakan dan umpan balik?
- Apakah iOS perlu didukung di MVP, atau Android saja?
- Apakah dashboard terapis cukup di dalam app, atau perlu web?
- Aturan streak final: batas minimal sesi valid, jumlah freeze, dan apakah Mode Rehab perlu indikator kepatuhan serupa tanpa tekanan streak?
- Hasil cek Play Store untuk pesaing lokal Indonesia.
