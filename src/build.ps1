$dir = 'C:\Users\sa\AppData\Local\Temp\claude\D--Dropbox-2--CLAUDE-AI-Bascis\21d2038a-d33c-4048-a305-9854f005caad\scratchpad'
$ErrorActionPreference = 'Stop'
function ReadJson($path) {
  $t = [IO.File]::ReadAllText($path).TrimStart([char]0xFEFF).Trim()
  $null = $t | ConvertFrom-Json
  return $t
}
$html = [IO.File]::ReadAllText("$dir\neurocourse-template.html")

$parts = @()
foreach ($n in 1..9) { $parts += ReadJson "$dir\extra$n.json" }
$html = $html.Replace('/*__EXTRAS__*/', ($parts -join ",`n"))
$html = $html.Replace('/*__M10__*/null', (ReadJson "$dir\module10.json"))
$html = $html.Replace('/*__M11__*/null', (ReadJson "$dir\module11.json"))
$html = $html.Replace('/*__DIGITS__*/null', (ReadJson "$dir\digits-hand.json"))

$letters = @{ en = '["A","B","C","D"]'; fr = '["A","B","C","D"]'; zh = '["A","B","C","D"]'; ar = '["' + [char]0x0623 + '","' + [char]0x0628 + '","' + [char]0x062C + '","' + [char]0x062F + '"]' }
$report = @()
$langsToBuild = @('en', 'fr', 'zh', 'ar')
foreach ($lang in $langsToBuild) {
  try {
    $mods = @()
    foreach ($n in 1..11) { $mods += ReadJson "$dir\$lang-module$n.json" }
    $exs = @()
    foreach ($n in 1..9) { $exs += ReadJson "$dir\$lang-extra$n.json" }
    $ui = ReadJson "$dir\$lang-ui.json"
    $demo = ReadJson "$dir\$lang-demodata.json"
    $meta = '{"demoData":' + $demo + ',"letters":' + $letters[$lang] + ',' + $ui.Substring($ui.IndexOf('{') + 1)
    $null = $meta | ConvertFrom-Json
    $pack = '{"course":[' + ($mods -join ",`n") + '],"extras":[' + ($exs -join ",`n") + '],"meta":' + $meta + '}'
    $null = $pack | ConvertFrom-Json
    $html = $html.Replace('/*__LANG_' + $lang.ToUpper() + '__*/null', $pack)
    $report += "$lang OK ($([math]::Round($pack.Length/1kb)) KB)"
  } catch {
    $report += "$lang FAIL: $($_.Exception.Message)"
  }
}
# версия для артефакта claude.ai — без обёртки (её добавляет платформа)
[IO.File]::WriteAllText("$dir\neurocourse.html", $html, (New-Object Text.UTF8Encoding($false)))

# версия для файла/GitHub Pages — полноценный HTML-документ с viewport и метатегами
$desc = 'Интерактивный курс о том, как работают нейросети и LLM — на 5 языках. 11 модулей, демонстрации, тесты, игра: обучите нейросеть распознавать цифры прямо в браузере.'
$i = $html.IndexOf('</style>') + 8
$headPart = $html.Substring(0, $i)
$bodyPart = $html.Substring($i)
$site = "<!doctype html>`n<html lang=`"ru`">`n<head>`n<meta charset=`"utf-8`">`n<meta name=`"viewport`" content=`"width=device-width, initial-scale=1`">`n<meta name=`"description`" content=`"$desc`">`n<meta property=`"og:title`" content=`"Внутри нейросети / Inside a Neural Network`">`n<meta property=`"og:description`" content=`"$desc`">`n<meta property=`"og:type`" content=`"website`">`n<link rel=`"icon`" href=`"data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 100 100'%3E%3Ctext y='.9em' font-size='90'%3E%F0%9F%A7%A0%3C/text%3E%3C/svg%3E`">`n" + $headPart + "`n</head>`n<body>`n" + $bodyPart + "`n</body>`n</html>"
[IO.File]::WriteAllText('D:\Dropbox\2. CLAUDE\AI Bascis\neurocourse\index.html', $site, (New-Object Text.UTF8Encoding($false)))
$siteDir = 'D:\Dropbox\2. CLAUDE\AI Bascis\neurocourse-site'
if (Test-Path $siteDir) { [IO.File]::WriteAllText("$siteDir\index.html", $site, (New-Object Text.UTF8Encoding($false))) }
"total: $([math]::Round($html.Length/1kb)) KB | " + ($report -join ' | ')