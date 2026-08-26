# src/page.html から公開用の index.html を作る
# 実行:  .\build.ps1
#
# src/page.html は <title> と <style> から始まる「中身だけ」のHTML。
# ここで <!doctype> や <head>（OGPタグを含む）を被せて完成させる。
#
# 注意: このファイルは UTF-8 (BOM付き) で保存すること。

Set-Location $PSScriptRoot
$ErrorActionPreference = "Stop"

$SITE = "https://yayoifps.github.io/reference-shelf/"
$src  = Get-Content "$PSScriptRoot\src\page.html" -Raw -Encoding UTF8

$marker = "</style>"
$i = $src.IndexOf($marker)
if ($i -lt 0) { Write-Host "src/page.html に </style> が見つかりません" -ForegroundColor Red; exit 1 }
$headPart = $src.Substring(0, $i + $marker.Length)
$bodyPart = $src.Substring($i + $marker.Length).Trim()

# カード数を数えて説明文に反映
$count = ([regex]::Matches($src, ',g:"')).Count
$desc  = "アニメ・ゲーム制作のための英語リファレンス検索ワード集。体の動き・カメラワーク・アニメの基礎の3フロア。カーソルで日本語の説明、クリックでコピー。"

# 改行を LF に統一（CSPのハッシュが環境で変わらないように）
$bodyPart = $bodyPart -replace "`r`n", "`n"
$headPart = $headPart -replace "`r`n", "`n"

# インラインscriptのSHA-256を取り、CSPで「このscriptだけ許可」する
$sm = [regex]::Match($bodyPart, '(?s)<script>(.*?)</script>')
if (-not $sm.Success) { Write-Host "script が見つかりません" -ForegroundColor Red; exit 1 }
$sha  = [System.Security.Cryptography.SHA256]::Create()
$hash = [Convert]::ToBase64String($sha.ComputeHash([System.Text.Encoding]::UTF8.GetBytes($sm.Groups[1].Value)))

$csp = "default-src 'none'; " +
       "img-src 'self' data:; " +
       "style-src 'self' 'unsafe-inline' https://fonts.googleapis.com; " +
       "font-src https://fonts.gstatic.com; " +
       "script-src 'sha256-$hash'; " +
       "base-uri 'none'; form-action 'none'"

$meta = @"
<meta charset="utf-8">
<meta http-equiv="Content-Security-Policy" content="$csp">
<meta name="referrer" content="no-referrer">
<meta name="description" content="$desc">
<meta name="theme-color" content="#E9E5DB">

<meta property="og:type" content="website">
<meta property="og:site_name" content="リファレンス検索ワード棚">
<meta property="og:locale" content="ja_JP">
<meta property="og:url" content="$SITE">
<meta property="og:title" content="リファレンス検索ワード棚">
<meta property="og:description" content="$desc">
<meta property="og:image" content="${SITE}ogp.png">
<meta property="og:image:type" content="image/png">
<meta property="og:image:width" content="1200">
<meta property="og:image:height" content="630">
<meta property="og:image:alt" content="棚に並んだ検索ワードのカード">

<meta name="twitter:card" content="summary_large_image">
<meta name="twitter:title" content="リファレンス検索ワード棚">
<meta name="twitter:description" content="$desc">
<meta name="twitter:image" content="${SITE}ogp.png">

<link rel="icon" href="data:image/svg+xml,<svg xmlns=%22http://www.w3.org/2000/svg%22 viewBox=%220 0 100 100%22><text y=%22.9em%22 font-size=%2290%22>📼</text></svg>">
<link rel="apple-touch-icon" href="${SITE}ogp.png">
"@

$out = "<!doctype html>`n<html lang=`"ja`">`n<head>`n" + ($meta -replace "`r`n","`n") + "`n" + $headPart +
       "`n</head>`n<body>`n" + $bodyPart + "`n</body>`n</html>`n"

[System.IO.File]::WriteAllText("$PSScriptRoot\index.html", $out, (New-Object System.Text.UTF8Encoding($false)))
$kb = [math]::Round((Get-Item "$PSScriptRoot\index.html").Length / 1kb)
Write-Host "index.html を生成しました（${kb} KB / カード ${count} 枚）" -ForegroundColor Green
