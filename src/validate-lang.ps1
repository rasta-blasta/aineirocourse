param([Parameter(Mandatory=$true)][string]$lang)
$dir = 'C:\Users\sa\AppData\Local\Temp\claude\D--Dropbox-2--CLAUDE-AI-Bascis\21d2038a-d33c-4048-a305-9854f005caad\scratchpad'
$issues = @()
function J($p) { ([IO.File]::ReadAllText($p).TrimStart([char]0xFEFF)) | ConvertFrom-Json }
foreach ($n in 1..11) {
  try {
    $s = J "$dir\module$n.json"; $e = J "$dir\$lang-module$n.json"
    if ($e.sections.Count -ne $s.sections.Count) { $issues += "m${n} sections $($e.sections.Count) vs $($s.sections.Count)" }
    if ($e.quiz.Count -ne 6) { $issues += "m${n} quiz $($e.quiz.Count)" }
    for ($q = 0; $q -lt 6; $q++) {
      if ($e.quiz[$q].correct -ne $s.quiz[$q].correct) { $issues += "m${n} q${q} correct" }
      if ($e.quiz[$q].options.Count -ne 4) { $issues += "m${n} q${q} options" }
    }
  } catch { $issues += "m${n}: $($_.Exception.Message)" }
}
foreach ($n in 10, 11) {
  try {
    $s = J "$dir\module$n.json"; $e = J "$dir\$lang-module$n.json"
    for ($q = 0; $q -lt 6; $q++) { if ($e.quiz2[$q].correct -ne $s.quiz2[$q].correct) { $issues += "m${n} quiz2 q${q} correct" } }
    if ($e.exercises.Count -ne 3) { $issues += "m${n} exercises" }
  } catch { $issues += "m${n} extras: $($_.Exception.Message)" }
}
try {
  $s11 = J "$dir\module11.json"; $e11 = J "$dir\$lang-module11.json"
  if ($e11.demo.Count -ne 10) { $issues += "m11 demo count" }
  for ($i = 0; $i -lt 10; $i++) { if ($e11.demo[$i].open -ne $s11.demo[$i].open) { $issues += "m11 demo${i} open" } }
} catch { $issues += "m11 demo: $($_.Exception.Message)" }
foreach ($n in 1..9) {
  try {
    $s = J "$dir\extra$n.json"; $e = J "$dir\$lang-extra$n.json"
    if ($e.quiz2.Count -ne 6) { $issues += "e${n} quiz2 count" }
    for ($q = 0; $q -lt 6; $q++) { if ($e.quiz2[$q].correct -ne $s.quiz2[$q].correct) { $issues += "e${n} q${q} correct" } }
    if ($e.exercises.Count -ne 3) { $issues += "e${n} exercises" }
  } catch { $issues += "e${n}: $($_.Exception.Message)" }
}
try {
  $keys = Get-Content "$dir\ui-keys.txt" -Encoding UTF8
  $ui = (J "$dir\$lang-ui.json").ui
  $miss = @(); foreach ($k in $keys) { if ($null -eq $ui.PSObject.Properties[$k]) { $miss += $k } }
  if ($miss.Count) { $issues += "ui missing $($miss.Count): $(($miss | Select-Object -First 5) -join ' | ')" }
  foreach ($k in $keys) {
    $p = $ui.PSObject.Properties[$k]
    if ($p) { foreach ($m in [regex]::Matches($k, '\{[A-Z]+\}')) { if ($p.Value -notlike "*$($m.Value)*") { $issues += "ui placeholder $($m.Value) lost in '$($k.Substring(0,[Math]::Min(40,$k.Length)))'" } } }
  }
} catch { $issues += "ui: $($_.Exception.Message)" }
try {
  $dd = J "$dir\$lang-demodata.json"
  if ($dd.words.Count -ne 24) { $issues += "words $($dd.words.Count)" }
  foreach ($v in 'A', 'B') {
    $var = $dd.attention.$v; $L = $var.toks.Count
    if ($var.sel -ge $L) { $issues += "att $v sel out of range" }
    foreach ($kk in $var.att.PSObject.Properties.Name) {
      if ([int]$kk -ge $L) { $issues += "att $v key $kk" }
      foreach ($jj in $var.att.$kk.PSObject.Properties.Name) { if ([int]$jj -ge $L) { $issues += "att $v idx $jj" } }
    }
  }
  $s1w = $dd.temp.s1 | ForEach-Object { $_[0] }
  foreach ($kk in $dd.temp.s2.PSObject.Properties.Name) { if ($s1w -notcontains $kk) { $issues += "temp s2 key '$kk' not in s1" } }
  $sd = J "$dir\demodata-ru.json"
  if ($dd.rlhf.Count -ne 4) { $issues += "rlhf count" }
  for ($i = 0; $i -lt 4; $i++) { for ($a = 0; $a -lt 2; $a++) { if ($dd.rlhf[$i].a[$a].good -ne $sd.rlhf[$i].a[$a].good) { $issues += "rlhf ${i}/${a} good" } } }
  if ($dd.rag.notes.Count -ne 6 -or $dd.rag.qs.Count -ne 4) { $issues += "rag counts" }
} catch { $issues += "demodata: $($_.Exception.Message)" }
if ($issues.Count) { "[$lang] ПРОБЛЕМЫ ($($issues.Count)):"; $issues | Select-Object -First 30 } else { "[$lang] ВСЕ ПРОВЕРКИ ПРОЙДЕНЫ" }