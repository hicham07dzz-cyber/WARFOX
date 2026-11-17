// Guided workflow: semantic AI analysis is required to unlock the next stage.
// Local pixel/audio measurements remain optional diagnostics and never count as AI understanding.
const $ = id => document.getElementById(id);
const panels = ["stepReference","stepClips","stepAnalysis","stepDesign","stepPreview"];
let referenceReady = false, clipsReady = false, analysisReady = false, exportReady = false;

function showStep(n) {
  panels.forEach((id, i) => $(id).classList.toggle("hidden", i + 1 !== n));
  document.querySelectorAll("[data-indicator]").forEach(el => {
    const k = Number(el.dataset.indicator);
    el.classList.toggle("active", k === n);
    el.classList.toggle("done", k < n);
  });
  window.scrollTo({ top: 0, behavior: "smooth" });
}

function afterAsync(el, property, callback) {
  const original = el[property];
  el[property] = async function (...args) {
    const result = await original?.apply(this, args);
    await callback();
    return result;
  };
}

const referenceInput = $("reference");
const clipsInput = $("clips");
const referenceAIButton = $("analyzeReferenceAI");
const clipsAIButton = $("analyzeClipsAI");
const continueClipsButton = $("continueToAnalysis");
const continueDesignButton = $("continueToDesign");
const exportButton = $("export");

continueClipsButton.disabled = true;
continueDesignButton.disabled = true;
exportButton.disabled = true;

afterAsync(referenceInput, "onchange", async () => {
  referenceReady = false;
  clipsReady = false;
  analysisReady = false;
  exportReady = false;
  $("aiReferenceStatus").textContent = referenceInput.files?.length
    ? "تم اختيار مرجع جديد. يجب تحليله دلالياً قبل المتابعة."
    : "التحليل الذكي يحتاج فيديو مرجعياً ومفتاح Gemini.";
  $("aiClipsStatus").textContent = "ينتظر تحليل المرجع واختيار المقاطع.";
  $("analysisStatus").textContent = referenceInput.files?.length
    ? "يمكنك إجراء القياسات المحلية، لكنها لا تفتح المرحلة التالية."
    : "بانتظار الفيديو المرجعي.";
  $("analysisResults").innerHTML = "";
  $("clipAnalysisResults").innerHTML = "";
  continueClipsButton.disabled = true;
  continueDesignButton.disabled = true;
  exportButton.disabled = true;
  showStep(1);
});

afterAsync(referenceAIButton, "onclick", async () => {
  const succeeded = $("aiReferenceStatus").textContent.startsWith("اكتمل الفهم الدلالي");
  if (!succeeded) return;
  referenceReady = true;
  showStep(2);
  $("clipLabel").textContent = "الآن ارفع المقاطع التي تريد مونتاجها";
  $("clipAnalysisStatus").textContent = "اختر مقاطعك ثم اضغط متابعة.";
});

afterAsync(clipsInput, "onchange", async () => {
  clipsReady = !!clipsInput.files?.length;
  analysisReady = false;
  exportReady = false;
  $("aiClipsStatus").textContent = clipsReady
    ? "تم اختيار المقاطع. يجب تحليل كل مقطع دلالياً قبل اعتماد الاختيار."
    : "ارفع المقاطع أولاً.";
  $("clipAnalysisResults").innerHTML = "";
  continueClipsButton.disabled = !referenceReady || !clipsReady;
  continueDesignButton.disabled = true;
  exportButton.disabled = true;
  $("clipAnalysisStatus").textContent = clipsReady
    ? "تم اختيار " + clipsInput.files.length + " مقاطع. القياسات المحلية اختيارية؛ تحليل Gemini مطلوب للمتابعة."
    : "ارفع المقاطع أولاً.";
});

continueClipsButton.onclick = () => {
  if (!referenceReady || !clipsInput.files?.length) return;
  clipsReady = true;
  showStep(3);
  $("clipAnalysisStatus").textContent = "حلّل المقاطع بالذكاء الاصطناعي، ثم راجع اللقطات المقترحة.";
};

afterAsync(clipsAIButton, "onclick", async () => {
  const succeeded = $("aiClipsStatus").textContent.startsWith("اكتمل فهم");
  if (!succeeded || !clipsReady) return;
  analysisReady = true;
  continueDesignButton.disabled = false;
  $("clipAnalysisStatus").textContent = "اكتمل التحليل الدلالي لجميع المقاطع. راجع اللقطات واقتراحات القص قبل المتابعة.";
});

continueDesignButton.onclick = () => {
  if (!analysisReady) return;
  exportReady = true;
  exportButton.disabled = false;
  showStep(4);
  $("status").textContent = "اضبط إعدادات المونتاج، ثم أنشئ ملف MP4.";
};

afterAsync(exportButton, "onclick", async () => {
  if (exportReady && $("status").textContent.startsWith("اكتمل التصدير")) showStep(5);
});

$("loadEngine").disabled = false;
showStep(1);
