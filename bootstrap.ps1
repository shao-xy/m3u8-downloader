# 保存为 download_video.ps1
param(
    [Parameter(Mandatory=$true)]
    [string]$Url,
    
    [Parameter(Mandatory=$true)]
    [string]$OutputFile
)

# 设置当前目录为脚本所在目录
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location -Path $ScriptDir

# 检查输出文件名是否为mp4格式
if (-not $OutputFile.EndsWith('.mp4')) {
    Write-Host "错误：输出文件名必须以.mp4结尾" -ForegroundColor Red
    Write-Host "当前文件名: $OutputFile" -ForegroundColor Yellow
    pause
    exit 1
}

# 创建临时目录
$TempDir = "./test/tmp"
if (-not (Test-Path $TempDir)) {
    New-Item -ItemType Directory -Path $TempDir | Out-Null
}

# 设置中间文件路径
$M3u8File = "$TempDir/index.m3u8"
$TsFile = "./test/one.ts"
$TempMp4 = "./test/one.mp4"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "开始下载和处理视频" -ForegroundColor Green
Write-Host "源URL: $Url" -ForegroundColor Yellow
Write-Host "输出文件: $OutputFile" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Cyan

# 步骤1：下载m3u8视频流列表文件
Write-Host "`n[1/4] 下载m3u8文件..." -ForegroundColor Green
python ./test/download.py download "$Url"
if ($LASTEXITCODE -ne 0) {
    Write-Host "错误：m3u8文件下载失败" -ForegroundColor Red
    pause
    exit 1
}
Write-Host "完成" -ForegroundColor Green

# 步骤2：下载视频片段
Write-Host "`n[2/4] 下载视频片段..." -ForegroundColor Green
python ./test/download.py parse "$M3u8File" -r "$Url"
if ($LASTEXITCODE -ne 0) {
    Write-Host "错误：视频片段下载失败" -ForegroundColor Red
    pause
    exit 1
}
Write-Host "完成" -ForegroundColor Green

# 步骤3：合并片段文件
Write-Host "`n[3/4] 合并视频片段..." -ForegroundColor Green
$RelTempDir = "./tmp"
python ./test/download.py combine "$M3u8File" -s "$RelTempDir" -d "$TsFile"
if ($LASTEXITCODE -ne 0) {
    Write-Host "错误：视频合并失败" -ForegroundColor Red
    pause
    exit 1
}
Write-Host "完成" -ForegroundColor Green

# 步骤4：转换为mp4格式
Write-Host "`n[4/4] 转换为mp4格式..." -ForegroundColor Green
ffmpeg -i "$TsFile" -c:v copy -c:a copy "$TempMp4" -hide_banner -loglevel error
if ($LASTEXITCODE -ne 0) {
    Write-Host "错误：MP4转换失败" -ForegroundColor Red
    pause
    exit 1
}
Write-Host "完成" -ForegroundColor Green

# 重命名为用户指定的文件名
Write-Host "`n重命名为最终文件名..." -ForegroundColor Green
if (Test-Path $TempMp4) {
    Move-Item -Path $TempMp4 -Destination $OutputFile -Force
    Write-Host "完成" -ForegroundColor Green
}

# 清理临时文件
Write-Host "`n清理临时文件..." -ForegroundColor Green
if (Test-Path $TsFile) { Remove-Item $TsFile }
if (Test-Path $TempDir) { Remove-Item $TempDir -Recurse -Force }
Write-Host "临时文件已清理" -ForegroundColor Green

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "处理完成！" -ForegroundColor Green
Write-Host "输出文件: $OutputFile" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Cyan

pause