# SNS共有用のサムネイル画像 ogp.png を作る（1200x630）
# 実行:  .\make-ogp.ps1
# 注意: このファイルは UTF-8 (BOM付き) で保存すること。

Add-Type -AssemblyName System.Drawing
Set-Location $PSScriptRoot

$W = 1200; $H = 630
$bmp = New-Object System.Drawing.Bitmap($W, $H)
$g   = [System.Drawing.Graphics]::FromImage($bmp)
$g.SmoothingMode     = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
$g.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAliasGridFit

function C($hex){ [System.Drawing.ColorTranslator]::FromHtml($hex) }
function Brush($hex){ New-Object System.Drawing.SolidBrush (C $hex) }

# 背景（サイトと同じ紙っぽいグレー）
$g.FillRectangle((Brush "#E9E5DB"), 0, 0, $W, $H)
$g.FillRectangle((Brush "#DFDACE"), 0, 0, $W, 232)
$g.FillRectangle((Brush "#CFC8B8"), 0, 231, $W, 2)

# フォント（日本語）
$fam = "Yu Gothic UI"
if (-not ([System.Drawing.FontFamily]::Families | Where-Object { $_.Name -eq $fam })) { $fam = "Meiryo" }
$fTitle = New-Object System.Drawing.Font($fam, 46, [System.Drawing.FontStyle]::Bold, [System.Drawing.GraphicsUnit]::Pixel)
$fSub   = New-Object System.Drawing.Font($fam, 23, [System.Drawing.FontStyle]::Regular, [System.Drawing.GraphicsUnit]::Pixel)
$fCard  = New-Object System.Drawing.Font($fam, 25, [System.Drawing.FontStyle]::Bold, [System.Drawing.GraphicsUnit]::Pixel)
$fEn    = New-Object System.Drawing.Font("Consolas", 14, [System.Drawing.FontStyle]::Regular, [System.Drawing.GraphicsUnit]::Pixel)
$fFoot  = New-Object System.Drawing.Font($fam, 22, [System.Drawing.FontStyle]::Bold, [System.Drawing.GraphicsUnit]::Pixel)
$fStock = New-Object System.Drawing.Font($fam, 21, [System.Drawing.FontStyle]::Regular, [System.Drawing.GraphicsUnit]::Pixel)

# ロゴ（黄色い札＋テープのリール2つ）
$g.FillRectangle((Brush "#FFD400"), 72, 66, 92, 92)
$g.FillEllipse((Brush "#241F00"), 90, 96, 30, 30)
$g.FillEllipse((Brush "#241F00"), 122, 96, 30, 30)
$g.FillRectangle((Brush "#FFD400"), 100, 106, 12, 12)
$g.FillRectangle((Brush "#FFD400"), 132, 106, 12, 12)

# タイトル
$g.DrawString("リファレンス検索ワード棚", $fTitle, (Brush "#22262A"), 186, 68)
$g.DrawString("アニメ・ゲーム制作のための英語リファレンス検索ワード集", $fSub, (Brush "#6E7176"), 190, 132)
$g.DrawString("カーソルで日本語の説明 → クリックでコピー → YouTubeへ", $fSub, (Brush "#6E7176"), 190, 170)

# 棚に並ぶカード
$cards = @(
  @{ja="歩き";       en="walk cycle";      col="#316B9B"; tag="移動"},
  @{ja="斬る";       en="katana cutting";  col="#8E3F86"; tag="剣・刀"},
  @{ja="リロード";   en="reload";          col="#5C6670"; tag="銃"},
  @{ja="パン";       en="pan shot";        col="#35899F"; tag="カメラ"},
  @{ja="三点照明";   en="three point";     col="#B08A1E"; tag="光"},
  @{ja="バウンス";   en="bouncing ball";   col="#A1512B"; tag="基礎"}
)
$x = 72; $y = 288; $cw = 168; $ch = 232; $gap = 20
foreach($c in $cards){
  $g.FillRectangle((Brush "#FFFFFF"), $x, $y, $cw, $ch)
  $g.FillRectangle((Brush $c.col), $x, $y, 14, $ch)                 # 背表紙
  $g.FillRectangle((Brush $c.col), ($x+14), $y, ($cw-14), 7)        # 上の帯
  $tint = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(30, (C $c.col)))
  $g.FillRectangle($tint, ($x+14), ($y+7), ($cw-14), ($ch-7))
  $g.FillRectangle((Brush "#FFD400"), ($x+26), ($y+20), 60, 22)     # 値札
  $g.DrawString($c.tag, $fEn, (Brush "#241F00"), ($x+30), ($y+22))
  $g.DrawString($c.ja, $fCard, (Brush "#22262A"), ($x+26), ($y+148))
  $g.DrawString($c.en, $fEn, (Brush "#6E7176"), ($x+27), ($y+184))
  for($i=0; $i -lt 26; $i++){                                       # バーコード
    $bw = @(2,1,3,1,2)[$i % 5]
    $g.FillRectangle((Brush "#22262A"), ($x+27+$i*5), ($y+206), $bw, 14)
  }
  $x += $cw + $gap
}
# 棚板
$g.FillRectangle((Brush "#C0AF93"), 60, ($y+$ch+10), 1080, 12)
$g.FillRectangle((Brush "#A08D6E"), 60, ($y+$ch+22), 1080, 4)

# 足元
$g.DrawString("3フロア 25棚 249本 在庫中", $fStock, (Brush "#6E7176"), 72, 566)
$sf = New-Object System.Drawing.StringFormat
$sf.Alignment = [System.Drawing.StringAlignment]::Far
$g.DrawString("yayoifps.github.io/reference-shelf", $fFoot, (Brush "#22262A"),
              (New-Object System.Drawing.RectangleF(0, 564, ($W-72), 40)), $sf)

$bmp.Save("$PSScriptRoot\ogp.png", [System.Drawing.Imaging.ImageFormat]::Png)
$g.Dispose(); $bmp.Dispose()
Write-Host "ogp.png を作成しました（${W}x${H}）" -ForegroundColor Green
