const $=id=>document.getElementById(id);
const panels=["stepReference","stepClips","stepAnalysis","stepDesign","stepPreview"];
function showStep(n){panels.forEach((id,i)=>$(id).classList.toggle("hidden",i+1!==n));document.querySelectorAll("[data-indicator]").forEach(el=>{const k=Number(el.dataset.indicator);el.classList.toggle("active",k===n);el.classList.toggle("done",k<n)});window.scrollTo({top:0,behavior:"smooth"})}
function wrapAsync(el,property,after){const original=el[property];el[property]=async function(...args){const result=await original?.apply(this,args);await after();return result}}
const ref=$("reference"),refBtn=$("analyzeReference"),clips=$("clips"),clipBtn=$("analyzeClips"),exportBtn=$("export");
wrapAsync(ref,"onchange",async()=>{showStep(1);$("analysisStatus").textContent="تم اختيار المرجع. اضغط ابدأ تحليل المرجع."; $("analysisResults").innerHTML="";$("continueToAnalysis").disabled=true;$("continueToDesign").disabled=true});
wrapAsync(refBtn,"onclick",async()=>{if($("analysisStatus").textContent.startsWith("اكتمل تحليل المرجع")){showStep(2);$("clipLabel").textContent="بانتظار مقاطعك";}});
wrapAsync(clips,"onchange",async()=>{$("continueToAnalysis").disabled=!clips.files?.length;$("continueToDesign").disabled=true;$("clipAnalysisStatus").textContent=clips.files?.length?"تم اختيار "+clips.files.length+" مقاطع. اضغط متابعة للتحليل.":"ارفع المقاطع أولاً."});
$("continueToAnalysis").onclick=()=>{if(!clips.files?.length)return;showStep(3);$("clipAnalysisStatus").textContent="اضغط تحليل المقاطع لفحصها."};
wrapAsync(clipBtn,"onclick",async()=>{const m=$("clipAnalysisStatus").textContent.match(/تم تحليل (\d+) من (\d+) مقاطع/);if(m&&m[1]===m[2])$("continueToDesign").disabled=false});
$("continueToDesign").onclick=()=>{if($("continueToDesign").disabled)return;showStep(4)};
wrapAsync(exportBtn,"onclick",async()=>{if($("status").textContent.startsWith("اكتمل التصدير"))showStep(5)});
showStep(1);
