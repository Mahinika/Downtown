Write-Host "Testing JobSystem fixes..." -ForegroundColor Cyan

# Check if Godot can compile the scripts
try {
    $result = & godot --headless --check-only downtown/project.godot 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "SUCCESS: No compilation errors!" -ForegroundColor Green
    } else {
        Write-Host "FAILED: Compilation errors found" -ForegroundColor Red
        $result | Select-Object -First 10 | ForEach-Object {
            Write-Host "  $_" -ForegroundColor Red
        }
    }
} catch {
    Write-Host "ERROR: Failed to run Godot check: $_" -ForegroundColor Red
}

Write-Host "Test complete." -ForegroundColor Cyan