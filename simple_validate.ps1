# Simple validation script for Downtown Godot project

Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "🏗️  Downtown Validation Starting" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan

# Check Godot
try {
    $version = godot --version 2>$null
    Write-Host "✅ Godot found: $version" -ForegroundColor Green
} catch {
    Write-Host "❌ Godot not found in PATH" -ForegroundColor Red
    exit 1
}

# Check project files
$files = @("downtown\project.godot", "downtown\scripts\main.gd", "downtown\scripts\validation.gd", "run_validation.gd")
foreach ($file in $files) {
    if (Test-Path $file) {
        Write-Host "✅ Found: $file" -ForegroundColor Green
    } else {
        Write-Host "❌ Missing: $file" -ForegroundColor Red
    }
}

Write-Host "`n🔧 Running automated validation..." -ForegroundColor Yellow

# Run the Godot validation script
try {
    $result = & godot --headless --script run_validation.gd 2>&1
    $exitCode = $LASTEXITCODE

    # Display the output
    $result | ForEach-Object { Write-Host $_ }

    Write-Host "`n=========================================" -ForegroundColor Cyan
    if ($exitCode -eq 0) {
        Write-Host "🎉 All validations passed!" -ForegroundColor Green
    } else {
        Write-Host "❌ Validation failed!" -ForegroundColor Red
    }
    exit $exitCode
} catch {
    Write-Host "❌ Failed to run validation: $_" -ForegroundColor Red
    exit 1
}