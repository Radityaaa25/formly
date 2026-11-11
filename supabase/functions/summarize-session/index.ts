// Supabase Edge Function: summarize-session (Groq LLM)
// Sesuai PRD Formly: FR-23 (Ringkasan sesi dalam bahasa Indonesia sederhana: 3 kalimat plus 1 saran praktis)
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { corsHeaders } from "../_shared/cors.ts";

const GROQ_API_KEY = Deno.env.get("GROQ_API_KEY");
const GROQ_MODEL = Deno.env.get("GROQ_SUMMARY_MODEL") || "llama-3.1-8b-instant";

serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    if (!GROQ_API_KEY) {
      return new Response(
        JSON.stringify({ error: "GROQ_API_KEY belum dikonfigurasi di secrets Supabase" }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }

    const body = await req.json();
    const {
      exerciseName = "Squat",
      reps = 30,
      score = 86,
      errors = [],
      painBefore = 2,
      painAfter = 2,
    } = body;

    const errorDescriptions = errors && errors.length > 0
      ? errors.map((e: { label: string; count: number }) => `${e.label} (${e.count}x)`).join(", ")
      : "tidak ada kesalahan signifikan";

    const prompt = `Data sesi latihan pengguna:
- Gerakan: ${exerciseName}
- Repetisi selesai: ${reps}
- Skor form rata-rata: ${score}/100
- Kesalahan terdeteksi: ${errorDescriptions}
- Skala nyeri sebelum latihan: ${painBefore}/10, setelah latihan: ${painAfter}/10

Tugas:
Tulis evaluasi performa latihan dalam Bahasa Indonesia dengan format TEPAT:
1. Bagian Ringkasan: Tepat 2 sampai 3 kalimat objektif, memotivasi, dan menyebut konsistensi atau perkembangan.
2. Bagian Tips: Tepat 1 kalimat saran praktis yang diawali kata "Tips: ".

Format JSON output wajib:
{
  "summary": "...",
  "tip": "Tips: ..."
}`;

    const response = await fetch("https://api.groq.com/openai/v1/chat/completions", {
      method: "POST",
      headers: {
        "Authorization": `Bearer ${GROQ_API_KEY}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        model: GROQ_MODEL,
        messages: [
          { role: "system", content: "Anda adalah analis biomekanik latihan Formly. Hasilkan keluaran JSON valid saja." },
          { role: "user", content: prompt },
        ],
        response_format: { type: "json_object" },
        temperature: 0.3,
        max_tokens: 300,
      }),
    });

    if (!response.ok) {
      const errText = await response.text();
      console.error("Groq Summary Error:", errText);
      return new Response(
        JSON.stringify({ error: "Gagal membuat ringkasan AI", details: errText }),
        { status: response.status, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }

    const data = await response.json();
    const parsed = JSON.parse(data.choices?.[0]?.message?.content ?? "{}");

    return new Response(
      JSON.stringify({
        summary: parsed.summary ?? "Gerakanmu stabil dari awal sampai akhir sesi.",
        tip: parsed.tip ?? "Tips: pertahankan ritme yang terkontrol di setiap repetisi.",
      }),
      { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } },
    );
  } catch (error) {
    console.error("Internal Error:", error);
    return new Response(
      JSON.stringify({ error: "Terjadi kesalahan internal pada server" }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } },
    );
  }
});
