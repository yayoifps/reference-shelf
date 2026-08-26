# index.html を直したあと、GitHub Pages に反映するスクリプト
#
#   .\publish.ps1                  … 変更をコミットして push
#   .\publish.ps1 -Message "説明"  … コミットメッセージを指定
#
# 初回だけ:  gh auth login --web --git-protocol https
#
# 注意: このファイルは UTF-8 (BOM付き) で保存すること。
#       BOMなしだと PowerShell 5.1 が Shift-JIS として読み、日本語で構文エラーになります。

param([string]$Message = "更新")

Set-Location $PSScriptRoot
$ErrorActionPreference = "Continue"   # native コマンドの stderr で止めないため

$user = "yayoifps"
$repo = "reference-shelf"

$gh = "$env:LOCALAPPDATA\Microsoft\WinGet\Packages\GitHub.cli_Microsoft.Winget.Source_8wekyb3d8bbwe\bin\gh.exe"
if (-not (Test-Path $gh)) {
  $c = Get-Command gh -ErrorAction SilentlyContinue
  if (-not $c) { Write-Host "gh が見つかりません。" -ForegroundColor Red; exit 1 }
  $gh = $c.Source
}

# 1. ログイン確認
& $gh auth status | Out-Null
if ($LASTEXITCODE -ne 0) {
  Write-Host "先にログインしてください:" -ForegroundColor Yellow
  Write-Host "  gh auth login --web --git-protocol https"
  exit 1
}

# 2. 変更があればコミット
git add -A
if ((git status --porcelain --untracked-files=no)) {
  git commit -q -m $Message
  Write-Host "コミットしました: $Message"
} else {
  Write-Host "コミットする変更はありません。"
}

# 3. push
git push origin main
if ($LASTEXITCODE -ne 0) { Write-Host "push に失敗しました。" -ForegroundColor Red; exit 1 }

# 4. Pages の状態を確認（未設定なら有効化）
& $gh api "repos/$user/$repo/pages" | Out-Null
if ($LASTEXITCODE -ne 0) {
  & $gh api -X POST "repos/$user/$repo/pages" -f "source[branch]=main" -f "source[path]=/" | Out-Null
  Write-Host "GitHub Pages を有効化しました。"
}

Write-Host ""
Write-Host "公開URL（反映まで1分ほど）:" -ForegroundColor Green
Write-Host "  https://$user.github.io/$repo/"
