# MrrorCityLib 本地校验脚本 (Windows)
# 等价于 CI 的一个子集: 语法编译检查 + 冒烟测试
# 需要 Luau 解释器: 自动下载官方二进制到 %LOCALAPPDATA%\mrr-luau (仅首次), 或 -
LuauPath 指定:
#   powershell -ExecutionPolicy Bypass -File tools\check.ps1
param(
	[string]$LuauPath = ""
)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot

function Get-LuauDir {
	if ($LuauPath -and (Test-Path $LuauPath)) { return $LuauPath }
	$cache = Join-Path $env:LOCALAPPDATA "mrr-luau"
	$luauExe = Join-Path $cache "luau.exe"
	$compileExe = Join-Path $cache "luau-compile.exe"
	if ((Test-Path $luauExe) -and (Test-Path $compileExe)) { return $cache }
	# 下载官方 Windows 构建
	$release = Invoke-RestMethod -Uri "https://api.github.com/repos/luau-lang/luau/releases/latest" -Headers @{ "User-Agent" = "mrr" }
	$asset = $release.assets | Where-Object { $_.name -match "windows" } | Select-Object -First 1
	if (-not $asset) { throw "未找到 Luau Windows 构建资产" }
	New-Item -ItemType Directory -Path $cache -Force | Out-Null
	$zip = Join-Path $cache "luau.zip"
	Invoke-WebRequest -Uri $asset.browser_download_url -OutFile $zip -Headers @{ "User-Agent" = "mrr" }
	Expand-Archive -Path $zip -DestinationPath $cache -Force
	return $cache
}

$luauDir = Get-LuauDir
$luau = Join-Path $luauDir "luau.exe"
$compile = Join-Path $luauDir "luau-compile.exe"

# luau 二进制不识别非 ASCII 路径参数: 复制到临时目录再检查
$srcCopy = Join-Path $env:TEMP "mrr-source.lua"
$exCopy = Join-Path $env:TEMP "mrr-example.lua"
Copy-Item (Join-Path $root "source.lua") $srcCopy -Force
Copy-Item (Join-Path $root "Example.lua") $exCopy -Force

Write-Host "[1/3] luau compile: source.lua" -ForegroundColor Cyan
& $compile $srcCopy *> $null
if ($LASTEXITCODE -ne 0) { throw "source.lua 编译失败" }

Write-Host "[2/3] luau compile: Example.lua" -ForegroundColor Cyan
& $compile $exCopy *> $null
if ($LASTEXITCODE -ne 0) { throw "Example.lua 编译失败" }

Write-Host "[3/3] 冒烟测试 (stub 环境跑全 API)" -ForegroundColor Cyan
node (Join-Path $root "tests\build.js")
# luau 二进制不识别非 ASCII 路径参数, 复制到临时目录再执行
$smokeCopy = Join-Path $env:TEMP "mrr-combined.lua"
Copy-Item (Join-Path $root "tests\combined.lua") $smokeCopy -Force
& $luau $smokeCopy
if ($LASTEXITCODE -ne 0) { throw "冒烟测试失败" }

Write-Host "ALL CHECKS PASSED" -ForegroundColor Green
