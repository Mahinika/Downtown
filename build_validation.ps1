# Build Validation Script for Downtown City Management Game
# PowerShell version for Windows environment
# This script automates error detection and validation for the Godot project

param(
    [switch]$SkipTests,
    [switch]$SkipPerformance,
    [string]$LogFile = "validation_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
)

# Colors for output (PowerShell)
$RED = "Red"
$GREEN = "Green"
$YELLOW = "Yellow"
$NC = "White" # Default

$PROJECT_DIR = Split-Path -Parent $MyInvocation.MyCommand.Path
$GODOT_PROJECT = Join-Path $PROJECT_DIR "downtown\project.godot"
$LOG_PATH = Join-Path $PROJECT_DIR $LogFile

# Global error counter
$global:ErrorCount = 0
$global:WarningCount = 0

# Logging function
function Log-Message {
    param([string]$Message, [string]$Color = "White")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "$timestamp - $Message"
    Write-Host $logMessage -ForegroundColor $Color
    Add-Content -Path $LOG_PATH -Value $logMessage
}

function Log-Error {
    param([string]$Message)
    $global:ErrorCount++
    Log-Message "ERROR: $Message" $RED
}

function Log-Warning {
    param([string]$Message)
    $global:WarningCount++
    Log-Message "WARNING: $Message" $YELLOW
}

function Log-Success {
    param([string]$Message)
    Log-Message "SUCCESS: $Message" $GREEN
}

# Check if Godot is available
function Test-Godot {
    Log-Message "Checking for Godot installation..."

    try {
        $godotVersion = & godot --version 2>$null
        if ($LASTEXITCODE -eq 0) {
            Log-Success "Godot found: $godotVersion"
            return $true
        } else {
            throw "Godot command failed"
        }
    } catch {
        Log-Error "Godot executable not found in PATH"
        Log-Error "Please ensure Godot is installed and in your PATH"
        return $false
    }
}

# Validate project structure
function Test-ProjectStructure {
    Log-Message "Validating project structure..."

    $requiredDirs = @(
        "downtown\scripts",
        "downtown\scenes",
        "downtown\data"
    )

    foreach ($dir in $requiredDirs) {
        $fullPath = Join-Path $PROJECT_DIR $dir
        if (!(Test-Path $fullPath -PathType Container)) {
            Log-Error "Required directory missing: $dir"
            return $false
        }
    }
    Log-Success "Project structure valid"

    $requiredFiles = @(
        "downtown\project.godot",
        "downtown\scripts\main.gd"
    )

    foreach ($file in $requiredFiles) {
        $fullPath = Join-Path $PROJECT_DIR $file
        if (!(Test-Path $fullPath -PathType Leaf)) {
            Log-Error "Required file missing: $file"
            return $false
        }
    }
    Log-Success "Required files present"
    return $true
}

# Check for compilation errors
function Test-Compilation {
    Log-Message "Checking for compilation errors..."

    try {
        $output = & godot --headless --check-only $GODOT_PROJECT 2>&1
        if ($LASTEXITCODE -eq 0) {
            Log-Success "No compilation errors detected"
            return $true
        } else {
            Log-Error "Compilation errors found"
            $output | ForEach-Object { Log-Error $_ }
            return $false
        }
    } catch {
        Log-Error "Failed to check compilation: $_"
        return $false
    }
}

# Validate scenes
function Test-Scenes {
    Log-Message "Validating scenes..."

    $mainScene = Join-Path $PROJECT_DIR "downtown\scenes\main.tscn"
    if (!(Test-Path $mainScene)) {
        Log-Error "Main scene not found: $mainScene"
        return $false
    }

    try {
        $output = & godot --headless --scene $mainScene --quit 2>&1
        if ($output -match "ERROR|error") {
            Log-Error "Scene loading errors detected"
            $output | ForEach-Object { Log-Error $_ }
            return $false
        } else {
            Log-Success "Main scene loads successfully"
            return $true
        }
    } catch {
        Log-Error "Failed to test scene loading: $_"
        return $false
    }
}

# Run automated tests
function Invoke-Tests {
    if ($SkipTests) {
        Log-Message "Skipping tests as requested"
        return $true
    }

    Log-Message "Running automated tests..."

    $testScript = Join-Path $PROJECT_DIR "downtown\scripts\test_suite.gd"
    if (!(Test-Path $testScript)) {
        Log-Warning "Test suite not found: $testScript"
        return $true
    }

    try {
        $output = & godot --headless --script $testScript 2>&1
        if ($LASTEXITCODE -eq 0) {
            Log-Success "All tests passed"
            return $true
        } else {
            Log-Error "Test failures detected"
            $output | ForEach-Object { Log-Error $_ }
            return $false
        }
    } catch {
        Log-Error "Failed to run tests: $_"
        return $false
    }
}

# Check resource files
function Test-Resources {
    Log-Message "Validating resource files..."

    $dataDir = Join-Path $PROJECT_DIR "downtown\data"
    $requiredDataFiles = @("buildings.json", "resources.json")

    foreach ($file in $requiredDataFiles) {
        $fullPath = Join-Path $dataDir $file
        if (!(Test-Path $fullPath)) {
            Log-Error "Required data file missing: $file"
            return $false
        }
    }
    Log-Success "All required data files present"
    return $true
}

# Performance check
function Test-Performance {
    if ($SkipPerformance) {
        Log-Message "Skipping performance checks as requested"
        return $true
    }

    Log-Message "Running performance checks..."
    Log-Warning "Performance checks not fully implemented yet"
    # Future: Implement actual performance monitoring
    return $true
}

# Generate validation report
function New-ValidationReport {
    Log-Message "Generating validation report..."

    Write-Host ""
    Write-Host "=========================================" -ForegroundColor Cyan
    Write-Host "📊 Validation Report" -ForegroundColor Cyan
    Write-Host "=========================================" -ForegroundColor Cyan
    Write-Host "Project: Downtown City Management Game"
    Write-Host "Date: $(Get-Date)"
    Write-Host "Errors: $global:ErrorCount"
    Write-Host "Warnings: $global:WarningCount"
    Write-Host "Log file: $LOG_PATH"
    Write-Host ""

    if ($global:ErrorCount -eq 0) {
        Write-Host "🎉 All validations passed!" -ForegroundColor $GREEN
        Write-Host "Status: READY FOR BUILD"
        return $true
    } else {
        Write-Host "❌ Validation failed with $global:ErrorCount errors" -ForegroundColor $RED
        Write-Host "Status: BUILD BLOCKED"
        return $false
    }
}

# Main execution
function Invoke-Main {
    Log-Message "Starting Downtown validation pipeline"

    $overallSuccess = $true

    # Run all validation steps
    if (!(Test-Godot)) { $overallSuccess = $false }
    if (!(Test-ProjectStructure)) { $overallSuccess = $false }
    if (!(Test-Resources)) { $overallSuccess = $false }
    if (!(Test-Compilation)) { $overallSuccess = $false }
    if (!(Test-Scenes)) { $overallSuccess = $false }
    if (!(Invoke-Tests)) { $overallSuccess = $false }
    if (!(Test-Performance)) { $overallSuccess = $false }

    $reportSuccess = New-ValidationReport

    Log-Message "Validation pipeline complete"

    return ($overallSuccess -and $reportSuccess)
}

# Run main function
$success = Invoke-Main
exit [int](!$success)