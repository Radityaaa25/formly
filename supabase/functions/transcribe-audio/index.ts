// Supabase Edge Function: transcribe-audio (Groq Whisper)
// Sesuai PRD Formly: FR-22 & §14 (Transkripsi suara on-demand, file audio dibuang dan TIDAK disimpan)
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { corsHeaders } from "../_shared/cors.ts";

const GROQ_API_KEY = Deno.env.get("GROQ_API_KEY");

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

    const formData = await req.formData();
    const file = formData.get("file");

    if (!file || !(file instanceof Blob)) {
      return new Response(
        JSON.stringify({ error: "File audio tidak ditemukan dalam form data" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }

    // Forward to Groq Whisper API
    const groqFormData = new FormData();
    groqFormData.append("file", file, "audio.m4a");
    groqFormData.append("model", "whisper-large-v3");
    groqFormData.append("language", "id");
    groqFormData.append("temperature", "0.0");

    const response = await fetch("https://api.groq.com/openai/v1/audio/transcriptions", {
      method: "POST",
      headers: {
        "Authorization": `Bearer ${GROQ_API_KEY}`,
      },
      body: groqFormData,
    });

    if (!response.ok) {
      const errText = await response.text();
      console.error("Groq Whisper Error:", errText);
      return new Response(
        JSON.stringify({ error: "Gagal mentranskripsi audio", details: errText }),
        { status: response.status, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }

    const data = await response.json();
    return new Response(
      JSON.stringify({ text: data.text?.trim() ?? "" }),
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
