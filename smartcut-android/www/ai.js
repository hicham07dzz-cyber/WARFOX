const MODEL = "gemini-3.5-flash-lite";
const KEY_SLOT = "smartcut_gemini_api_key";

export function getAIKey() {
  return localStorage.getItem(KEY_SLOT) || "";
}
export function saveAIKey(value) {
  const key = String(value || "").trim();
  if (key) localStorage.setItem(KEY_SLOT, key);
  else localStorage.removeItem(KEY_SLOT);
  return key;
}
async function sampleFrames(file, maxFrames = 8) {
  const video = document.createElement("video");
  const url = URL.createObjectURL(file);
  video.muted = true;
  video.playsInline = true;
  video.preload = "auto";
  video.src = url;
  try {
    await new Promise((resolve, reject) => {
      video.onloadedmetadata = resolve;
      video.onerror = () => reject(new Error("تعذر فتح الفيديو"));
    });
    const duration = video.duration;
    if (!Number.isFinite(duration) || duration <= 0) throw new Error("مدة الفيديو غير صالحة");
    const canvas = document.createElement("canvas");
    const scale = Math.min(1, 768 / Math.max(video.videoWidth, video.videoHeight));
    canvas.width = Math.max(1, Math.round(video.videoWidth * scale));
    canvas.height = Math.max(1, Math.round(video.videoHeight * scale));
    const ctx = canvas.getContext("2d");
    const frames = [];
    for (let i = 0; i < maxFrames; i++) {
      const time = Math.min(duration - 0.05, Math.max(0, duration * (i + 0.5) / maxFrames));
      video.currentTime = time;
      await new Promise((resolve, reject) => {
        video.onseeked = resolve;
        video.onerror = () => reject(new Error("تعذر استخراج إطار من الفيديو"));
      });
      ctx.drawImage(video, 0, 0, canvas.width, canvas.height);
      const base64 = canvas.toDataURL("image/jpeg", 0.72).split(",")[1];
      frames.push({ time: Number(time.toFixed(2)), base64 });
    }
    return { duration, frames };
  } finally {
    URL.revokeObjectURL(url);
  }
}
function extractJson(text) {
  const clean = text.replace(/```json|\`\`\`/g, "").trim();
  const start = clean.indexOf("{");
  const end = clean.lastIndexOf("}");
  if (start < 0 || end <= start) throw new Error("لم يرجع النموذج نتيجة منظمة");
  return JSON.parse(clean.slice(start, end + 1));
}
export async function analyzeVideoWithGemini(file, apiKey, mode = "reference") {
  if (!apiKey) throw new Error("أدخل مفتاح Gemini أولاً");
  const { duration, frames } = await sampleFrames(file, mode === "reference" ? 16 : 8);
  const instruction = mode === "reference"
    ? "حلل أسلوب المونتاج في الفيديو المرجعي من الإطارات المعروضة فقط. لا تدّع معرفة الصوت أو الانتقالات غير المرئية. أعد JSON فقط بمفاتيح: summary, genre, color_style, pacing, camera_and_motion, editing_recipe (array), overlay_ideas (array), confidence, visual_recipe, edit_plan. اجعل visual_recipe كائناً قابلاً للتطبيق يحتوي brightness_adjustment رقم بين -0.12 و0.12، contrast رقم بين 0.85 و1.25، saturation رقم بين 0.7 و1.3، look إحدى القيم natural/cinematic/vivid/warm/clean، transition إحدى القيم cut/fade/crossfade. أنشئ edit_plan كمصفوفة من 4 إلى 12 لقطة متتابعة تغطي مدة الفيديو كاملة تقريبياً. لكل عنصر: start_sec, end_sec, duration_sec, visual_description, footage_request (ما اللقطة التي يجب أن يرسلها المستخدم)، transition_to_next, effect, overlay_text, timing_confidence. استخرج الأزمنة التقريبية من التغيرات المرئية فقط، واجعل المدد منطقية ومتنوعة مثل 2 أو 3 أو 4 ثوانٍ إذا كان الإيقاع يوحي بذلك. لا تزعم اكتشاف نبض الموسيقى من دون صوت. اذكر أن التوقيت تقديري إذا كانت الإطارات لا تكفي لتحديد القطع بدقة. لا تنسخ محتوى محمياً؛ صف بنية الأسلوب فقط."
    : "افهم محتوى هذا المقطع بصرياً. حدّد الأحداث المهمة فعلياً، واذكر أوقاتاً تقريبية بالثواني ضمن مدة الفيديو. لا تخترع أحداثاً غير ظاهرة. أعد JSON فقط بمفاتيح: summary, scenes (array of objects with start, end, description, importance 1-5, reason), best_moments (array of objects with start, end, reason), suggested_caption, confidence.";
  const parts = [{ text: instruction + "\nمدة الفيديو: " + duration.toFixed(2) + " ثانية. كل صورة تحمل توقيتها بالثواني." }];
  for (const frame of frames) {
    parts.push({ text: "إطار عند " + frame.time + " ثانية" });
    parts.push({ inline_data: { mime_type: "image/jpeg", data: frame.base64 } });
  }
  const response = await fetch("https://generativelanguage.googleapis.com/v1beta/models/" + MODEL + ":generateContent", {
    method: "POST",
    headers: { "Content-Type": "application/json", "x-goog-api-key": apiKey },
    body: JSON.stringify({
      contents: [{ role: "user", parts }],
      generationConfig: { temperature: 0.2, responseMimeType: "application/json" }
    })
  });
  const data = await response.json().catch(() => ({}));
  if (!response.ok) throw new Error(data.error?.message || ("Gemini API error " + response.status));
  const text = data.candidates?.[0]?.content?.parts?.map(p => p.text || "").join("\n");
  if (!text) throw new Error("لم يرجع Gemini نتيجة. تحقق من المفتاح أو حدود الخدمة.");
  return { duration, result: extractJson(text), sampledFrames: frames.length, model: MODEL };
}
