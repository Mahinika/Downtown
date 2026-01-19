# Pre-commit hook for GDScript validation (PowerShell)
# Install: Copy to .git/hooks/pre-commit or run: npm run install:hooks

Write-Host "Running GDScript validation..." -ForegroundColor Cyan

# Run validation script
npm run validate

# Exit with validation result
if ($LASTEXITCODE -ne 0) {
    Write-Host ""
    Write-Host "❌ Pre-commit validation failed!" -ForegroundColor Red
    Write-Host "Fix the errors above before committing." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "To skip validation (not recommended):" -ForegroundColor Yellow
    Write-Host "  git commit --no-verify" -ForegroundColor Gray
    exit 1
}

Write-Host "✅ Pre-commit validation passed" -ForegroundColor Green
exit 0
