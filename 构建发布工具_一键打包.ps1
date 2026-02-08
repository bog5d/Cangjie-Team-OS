# === 仓颉打包流水线 (V3.1 Robust) ===
$ErrorActionPreference = "Stop"

Write-Host " [1/4] 检查弹药 (PyInstaller)..." -ForegroundColor Yellow
# 强制安装/更新打包工具
pip install pyinstaller -q

Write-Host " [2/4] 正在铸造武器 (编译EXE)..." -ForegroundColor Yellow
$pyFile = "资产管理主程序.py"
if (-not (Test-Path $pyFile)) { Write-Host " 错误：核心代码 [$pyFile] 丢失！"; exit }

# === 关键修改：使用 python -m PyInstaller 绕过路径问题 ===
python -m PyInstaller --onefile --clean --name "仓颉系统_点击即运行" $pyFile

Write-Host " [3/4] 封装交付包..." -ForegroundColor Yellow
$releaseDir = Join-Path (Get-Location) "交付给团队_最终版"
if (Test-Path $releaseDir) { Remove-Item $releaseDir -Recurse -Force }
New-Item -ItemType Directory -Path $releaseDir | Out-Null

# 移动成品
Move-Item "dist\仓颉系统_点击即运行.exe" $releaseDir
# 复制俏皮话配置
Copy-Item "00_系统配置_俏皮话.csv" $releaseDir -ErrorAction SilentlyContinue

# 写入小白说明书
$readme = "【使用说明】`r`n1. 双击EXE直接运行。`r`n2. 俏皮话改配置表就行。`r`n3. 遇到红色报错请截图给王波。"
[System.IO.File]::WriteAllText((Join-Path $releaseDir "使用说明.txt"), $readme, [System.Text.Encoding]::UTF8)

# 清理战场
Remove-Item "build", "dist", "*.spec" -Recurse -Force -ErrorAction SilentlyContinue

Write-Host "`n 打包成功！" -ForegroundColor Green
Write-Host " 交付包位置: $releaseDir" -ForegroundColor Cyan
Write-Host " 现在可以把这个文件夹发给小雷了。" -ForegroundColor White