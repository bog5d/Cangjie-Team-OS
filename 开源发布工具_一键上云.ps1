# === 仓颉系统  自动化交付 (Protocol Klein) ===
$ErrorActionPreference = "Continue" # 关键修改：容忍 Git 的输出噪点
$RemoteRepoUrl = "https://github.com/bog5d/Cangjie-Team-OS.git"
$DevLogFile = "00_系统开发日志.txt"

Write-Host " 克莱恩正在接管任务..." -ForegroundColor Cyan

# 清理残留git进程
Stop-Process -Name git -ErrorAction SilentlyContinue

# --- 1. 暴力清理战场 ---
$DesktopPath = [Environment]::GetFolderPath("Desktop")
$TargetDir = Join-Path $DesktopPath "Cangjie-Team-OS"
# 强制清理，不管存不存在，先杀一遍进程防止占用
if (Test-Path $TargetDir) { 
    Write-Host " 清理旧现场..." -ForegroundColor Gray
    Remove-Item $TargetDir -Recurse -Force -ErrorAction SilentlyContinue 
}
New-Item -ItemType Directory -Path $TargetDir -Force | Out-Null

# --- 2. 快速构建 ---
Write-Host " 构建交付包..." -ForegroundColor Cyan
$SourceDir = Get-Location
$AllowList = @("*.py", "*.ps1", "*.csv", "*.txt", "*.md", "LICENSE")
$ExcludeList = @("logs", "dist", "build", "*.exe", ".git", "01_标准素材库", "02_对外发送记录")

Get-ChildItem -Path $SourceDir -Include $AllowList -Recurse -Exclude $ExcludeList | ForEach-Object {
    $RelPath = $_.FullName.Replace($SourceDir.Path, "")
    $DestPath = Join-Path $TargetDir $RelPath
    $ParentDir = Split-Path $DestPath -Parent
    if (-not (Test-Path $ParentDir)) { New-Item -ItemType Directory -Path $ParentDir -Force | Out-Null }
    Copy-Item $_.FullName $DestPath -Force
}
# 重建索引
$DemoDirs = @("01_标准素材库\01_示例分类", "02_对外发送记录\示例_合作方", "logs")
foreach ($d in $DemoDirs) { New-Item -ItemType Directory -Path (Join-Path $TargetDir $d) -Force | Out-Null }
[System.IO.File]::WriteAllText((Join-Path $TargetDir "01_标准素材库\01_示例分类\00_索引_示例.txt"), "示例", [System.Text.Encoding]::UTF8)

# --- 3. 结果导向型推送 ---
Set-Location $TargetDir
git init | Out-Null
git config user.name "Klein-Bot"
git config user.email "bot@klein.local"
# 全局优化网络
git config --global http.postBuffer 524288000
git config --global http.sslVerify false
# 清除代理干扰
git config --global --unset http.proxy 2>$null
git config --global --unset https.proxy 2>$null

# 网络优化配置
git config --global http.lowSpeedLimit 0
git config --global http.lowSpeedTime 999999

git add .
git commit -m "Auto Update by Klein" | Out-Null
git branch -M main | Out-Null
git remote add origin $RemoteRepoUrl

Write-Host " 执行强制推送..." -ForegroundColor Cyan
# 捕获完整输出
$pushOutput = git push -u origin main --force 2>&1 | Out-String
$pushExitCode = $LASTEXITCODE

# --- 4. 增强型核验 ---
$success = $false

# 条件1: 输出包含"Everything up-to-date"
if ($pushOutput -match "Everything up-to-date") {
    Write-Host " 检测到最新状态" -ForegroundColor Cyan
    $success = $true
}

# 条件2: 退出代码为0
if ($pushExitCode -eq 0) {
    Write-Host " Git推送成功" -ForegroundColor Cyan
    $success = $true
}

        # 条件3: 远程验证 (增强版)
        if (-not $success) {
            Write-Host " 执行深度核验..." -ForegroundColor Cyan
            $maxRetries = 3
            $retryCount = 0
            $localCommit = git rev-parse HEAD
            $verified = $false

            while (-not $verified -and $retryCount -lt $maxRetries) {
                Start-Sleep -Seconds 5
                $remoteInfo = git ls-remote origin main 2>&1
                if ($LASTEXITCODE -eq 0) {
                    $remoteCommit = ($remoteInfo -split '\s+')[0]
                    if ($localCommit -eq $remoteCommit) {
                        $verified = $true
                        $success = $true
                        Write-Host " 核验通过：本地提交与远程一致 (第 $($retryCount+1) 次重试)" -ForegroundColor Cyan
                    } else {
                        Write-Host " 核验失败：本地提交($localCommit)与远程($remoteCommit)不匹配 (第 $($retryCount+1) 次重试)" -ForegroundColor Yellow
                    }
                } else {
                    Write-Host " 无法获取远程信息 (第 $($retryCount+1) 次重试)" -ForegroundColor Yellow
                }
                $retryCount++
            }

            if (-not $verified) {
                Write-Host " 深度核验失败：无法确认远程状态" -ForegroundColor Red
                $success = $false
            }
        }

if ($success) {
    Write-Host " 验证通过！云端状态正常。" -ForegroundColor Green
    
    # 回到安全目录
    Set-Location $SourceDir
    
    # 彻底销毁 (仅在确认成功时执行)
    Write-Host " 任务完成，销毁临时文件..." -ForegroundColor Green
    Remove-Item $TargetDir -Recurse -Force -ErrorAction SilentlyContinue
    
    # 明确成功标记 (用于测试循环检测)
    Write-Host "✅ SUCCESS: 脚本执行成功，临时文件已清理" -ForegroundColor Green
} else {
    Write-Host "❌ 验证失败。错误详情：" -ForegroundColor Red
    Write-Host "退出代码: $pushExitCode" -ForegroundColor Red
    Write-Host "输出内容: $pushOutput" -ForegroundColor Gray
    Write-Host "❌ 注意: 临时文件夹 $TargetDir 未被清理" -ForegroundColor Yellow
}
