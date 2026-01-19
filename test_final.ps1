Write-Host "Final compilation test..." -ForegroundColor Cyan

try {
    $result = godot --headless --check-only downtown/project.godot 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "SUCCESS: No compilation errors!" -ForegroundColor Green
    } else {
        Write-Host "FAILED: Compilation errors found" -ForegroundColor Red
        $result | Select-Object -First 10 | ForEach-Object {
            Write-Host "  $_" -ForegroundColor Red
        }
        exit 1
    }
} catch {
    Write-Host "Godot not available for testing" -ForegroundColor Yellow
}

Write-Host "Test complete." -ForegroundColor Cyan