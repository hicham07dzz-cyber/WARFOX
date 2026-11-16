// Guided workflow controller: each stage unlocks only after its prerequisite succeeds.
const $ = id => document.getElementById(id);
const panels = ["stepReference","stepClips","stepAnalysis","stepDesign","stepPreview"];
let referenceReady = false, clipsReady = false, analysisReady = false, exportReady = false;
function showStep(n) {
  panels.forEach((id,i) => $(id).classList.toggle("hidden", i + 1 !== n));
  document.querySelectorAll("[data-indicator]").forEach(el => {
    const k = Number(el.dataset.indicator);
    el.classList.toggle("active", k === n);
    el.classList.toggle("done", k < n);
  });
  window.scrollTo({top:0, behavior:"smooth"});
}
function wrapAsync(el, property, after) {
  const original = el[property];
  el[property] = async function(...args) {
    const result = await original?.apply(this,args);
    await after();
    return result;
  };
}
const ref = $("reference"), refBtn = $("analyzeReference");
const clips = $("clips"), clipBtn = $("analyzeClips"), exportBtn = $("export");
const continueClips = $("continueToAnalysis"), continueDesign = $("continueToDesign");
exportBtn.disabled = true;
continueClips.disabled = true;
continueDesign.disabled = true;

wrapAsync(ref, "onchange", async () => {
  referenceReady = false; clipsReady = false; analysisReady = false; exportReady = false;
  $("analysisStatus").textContent = ref.files?.length ? "تم اختيار المرجع. اضغط «ابدأ تحليل المرجع»." : "اختر فيديو مرجعياً للبدء.";
  $("analysisResults").innerHTML = "";
  $("clipAnalysisResults").innerHTML = "";
  $("continueToAnalysis").disabled = true;
  $("continueToDesign").disabled = true;
  $("export").disabled = true;
  showStep(1);
});
wrapAsync($("analyzeReferenceAI"), "onclick", async () => {
  if ($("aiReferenceStatus").textContent.startsWith("اكتمل الفهم الدلالي")) {
    referenceReady = true;
    showStep(2);
    $("clipLabel").textContent = "الآن ارفع المقاطع التي تريد مونتاجها";
    $("clipAnalysisStatus").textContent = "بعد اختيار مقاطعك اضغط متابعة.";
  }
});
wrapAsync(refBtn, "onclick", async () => {
  referenceReady = $("analysisStatus").textContent.startsWith("اكتمل تحليل المرجع");
  if (referenceReady) {
    showStep(2);
    $("clipLabel").textContent = "الآن ارفع المقاطع التي تريد مونتاجها";
    $("clipAnalysisStatus").textContent = "بعد اختيار مقاطعك اضغط متابعة.";
  }
});
wrapAsync(clips, "onchange", async () => {
  clipsReady = !!clips.files?.length;
  analysisReady = false; exportReady = false;
  $("continueToAnalysis").disabled = !clipsReady;
  $("continueToDesign").disabled = true;
  $("export").disabled = true;
  $("clipAnalysisResults").innerHTML = "";
  $("clipAnalysisStatus").textContent = clipsReady
    ? "تم اختيار " + clips.files.length + " مقاطع. اضغط متابعة للانتقال إلى تحليلها."
    : "ارفع المقاطع أولاً.";
});
continueClips.onclick = () => {
  if (!referenceReady || !clips.files?.length) return;
  clipsReady = true;
  showStep(3);
  $("clipAnalysisStatus").textContent = "اضغط «تحليل المقاطع» وانتظر حتى ينتهي فحص جميع المقاطع.";
};
wrapAsync($("analyzeClipsAI"), "onclick", async () => {
  if ($("aiClipsStatus").textContent.startsWith("اكتمل فهم")) {
    analysisReady = true;
    $("continueToDesign").disabled = false;
    $("clipAnalysisStatus").textContent = "اكتمل الفهم الدلالي للمقاطع. راجع اللقطات المقترحة ثم تابع.";
  }
});
wrapAsync(clipBtn, "onclick", async () => {
  const status = $("clipAnalysisStatus").textContent;
  const match = status.match(/تم تحليل (\d+) من (\d+) مقاطع/);
  analysisReady = !!(match && match[1] === match[2] && Number(match[2]) === clips.files.length);
  $("continueToDesign").disabled = !analysisReady;
  if (analysisReady) $("clipAnalysisStatus").textContent += " — اكتمل التحليل. راجع الاقتراحات ثم اعتمدها للانتقال.";
});
continueDesign.onclick = () => {
  if (!analysisReady) return;
  exportReady = true;
  $("export").disabled = false;
  showStep(4);
  $("status").textContent = "اضبط تصميمك، ثم اضغط إنشاء MP4.";
};
wrapAsync(exportBtn, "onclick", async () => {
  if (exportReady && $("status").textContent.startsWith("اكتمل التصدير")) showStep(5);
});
$("loadEngine").disabled = false;
showStep(1);
