# Simple validation script for Downtown Godot project

Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "🏗️  Downtown Validation Starting" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan

$projectDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$godotProject = Join-Path $projectDir "downtown\project.godot"

# Check if Godot exists
try {
    $godotVersion = & godot --version 2>$null
    Write-Host "✅ Godot found: $godotVersion" -ForegroundColor Green
} catch {
    Write-Host "❌ Godot not found in PATH" -ForegroundColor Red
    exit 1
}

# Check project structure
$requiredFiles = @(
    "downtown\project.godot",
    "downtown\scripts\main.gd"
)

$allFilesExist = $true
foreach ($file in $requiredFiles) {
    $fullPath = Join-Path $projectDir $file
    if (!(Test-Path $fullPath)) {
        Write-Host "❌ Missing file: $file" -ForegroundColor Red
        $allFilesExist = $false
    } else {
        Write-Host "✅ Found: $file" -ForegroundColor Green
    }
}

# Check compilation
Write-Host "`n🔧 Checking compilation..." -ForegroundColor Yellow
try {
    $output = & godot --headless --check-only $godotProject 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ No compilation errors" -ForegroundColor Green
    } else {
        Write-Host "❌ Compilation errors found:" -ForegroundColor Red
        $output | ForEach-Object { Write-Host "   $_" -ForegroundColor Red }
        exit 1
    }
} catch {
    Write-Host "❌ Failed to check compilation: $_" -ForegroundColor Red
    exit 1
}

# Check main scene
Write-Host "`n🎬 Checking main scene..." -ForegroundColor Yellow
$mainScene = Join-Path $projectDir "downtown\scenes\main.tscn"
if (!(Test-Path $mainScene)) {
    Write-Host "❌ Main scene not found" -ForegroundColor Red
    exit 1
}

try {
    $output = & godot --headless --scene $mainScene --quit 2>&1
    if ($output -match "ERROR|error") {
        Write-Host "❌ Scene loading errors:" -ForegroundColor Red
        $output | ForEach-Object { Write-Host "   $_" -ForegroundColor Red }
        exit 1
    } else {
        Write-Host "✅ Main scene loads successfully" -ForegroundColor Green
    }
} catch {
    Write-Host "❌ Failed to test scene: $_" -ForegroundColor Red
    exit 1
}

# Final report
Write-Host "`n=========================================" -ForegroundColor Cyan
Write-Host "Validation Complete!" -ForegroundColor Green
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "All checks passed - Ready for development!" -ForegroundColor Green