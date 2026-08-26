# GitHub Pages へ公開するスクリプト
# 事前に一度だけ:  gh auth login --web --git-protocol https
# 実行:            .\publish.ps1
# 2回目以降に実行しても壊れません（あるものはスキップします）。

$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot

$gh = "$env:LOCALAPPDATA\Microsoft\WinGet\Packages\GitHub.cli_Microsoft.Winget.Source_8wekyb3d8bbwe\bin\gh.exe"
if (-not (Test-Path $gh)) { $gh = (Get-Command gh -ErrorAction Stop).Source }

# 1. ログイン確認
& $gh auth status
if ($LASTEXITCODE -ne 0) {
  Write-Host ""
  Write-Host "先に次を実行してログインしてください:" -ForegroundColor Yellow
  Write-Host "  gh auth login --web --git-protocol https"
  exit 1
}

# 2. ユーザー名を取得し、コミット作者を noreply アドレスに直す
$user = (& $gh api user --jq .login).Trim()
Write-Host "GitHub ユーザー: $user"
git config user.name  $user
git config user.email "$user@users.noreply.github.com"
git commit --amend --reset-author --no-edit -q

# 3. 公開リポジトリを作って push
$repo = "reference-shelf"
& $gh repo view "$user/$repo" *> $null
if ($LASTEXITCODE -ne 0) {
  & $gh repo create $repo --public --source . --remote origin --push `
      --description "アニメ・ゲーム制作用の英語リファレンス検索ワード66本。クリックでコピーしてYouTubeへ。"
} else {
  if (-not (git remote)) { git remote add origin "https://github.com/$user/$repo.git" }
  git push -u origin main --force-with-lease
}

# 4. GitHub Pages を有効化（main / root）
& $gh api "repos/$user/$repo/pages" *> $null
if ($LASTEXITCODE -ne 0) {
  & $gh api -X POST "repos/$user/$repo/pages" `
      -f "source[branch]=main" -f "source[path]=/" | Out-Null
  Write-Host "GitHub Pages を有効化しました。"
} else {
  Write-Host "GitHub Pages は有効化済みです。"
}

# 5. 公開URL
Write-Host ""
Write-Host "公開URL（反映まで1〜2分かかります）:" -ForegroundColor Green
Write-Host "  https://$user.github.io/$repo/"
