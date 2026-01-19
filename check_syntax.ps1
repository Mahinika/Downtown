# Quick syntax check
Write-Host "Checking syntax..." -ForegroundColor Cyan

try {
    # Try to parse the Villager.gd file for basic syntax issues
    $content = Get-Content "downtown\scripts\Villager.gd" -Raw
    Write-Host "File loaded successfully" -ForegroundColor Green

    # Basic checks
    $openBraces = ($content -split '{' | Measure-Object).Count - 1
    $closeBraces = ($content -split '}' | Measure-Object).Count - 1

    Write-Host "Open braces: $openBraces" -ForegroundColor Yellow
    Write-Host "Close braces: $closeBraces" -ForegroundColor Yellow

    if ($openBraces -eq $closeBraces) {
        Write-Host "Brace balance: OK" -ForegroundColor Green
    } else {
        Write-Host "Brace imbalance detected!" -ForegroundColor Red
    }

    # Check for basic syntax patterns
    $funcCount = ($content | Select-String -Pattern "func " -AllMatches).Matches.Count
    Write-Host "Functions found: $funcCount" -ForegroundColor Cyan

} catch {
    Write-Host "Error checking syntax: $_" -ForegroundColor Red
}

Write-Host "Syntax check complete." -ForegroundColor Cyan