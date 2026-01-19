#!/bin/bash

# Build Validation Script for Downtown City Management Game
# This script automates error detection and validation for the Godot project

set -e  # Exit on any error

echo "========================================="
echo "🏗️  Downtown Build Validation Starting"
echo "========================================="

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GODOT_PROJECT="$PROJECT_DIR/downtown/project.godot"
LOG_FILE="$PROJECT_DIR/validation_$(date +%Y%m%d_%H%M%S).log"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Logging function
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $*" | tee -a "$LOG_FILE"
}

error() {
    echo -e "${RED}❌ ERROR: $*${NC}" | tee -a "$LOG_FILE"
}

warning() {
    echo -e "${YELLOW}⚠️  WARNING: $*${NC}" | tee -a "$LOG_FILE"
}

success() {
    echo -e "${GREEN}✅ SUCCESS: $*${NC}" | tee -a "$LOG_FILE"
}

# Check if Godot is available
check_godot() {
    log "Checking for Godot installation..."
    if ! command -v godot &> /dev/null; then
        error "Godot executable not found in PATH"
        error "Please ensure Godot is installed and in your PATH"
        exit 1
    fi
    success "Godot found: $(godot --version)"
}

# Validate project structure
validate_project_structure() {
    log "Validating project structure..."

    # Check required directories
    local required_dirs=("downtown/scripts" "downtown/scenes" "downtown/data")
    for dir in "${required_dirs[@]}"; do
        if [ ! -d "$PROJECT_DIR/$dir" ]; then
            error "Required directory missing: $dir"
            return 1
        fi
    done
    success "Project structure valid"

    # Check required files
    local required_files=("downtown/project.godot" "downtown/scripts/main.gd")
    for file in "${required_files[@]}"; do
        if [ ! -f "$PROJECT_DIR/$file" ]; then
            error "Required file missing: $file"
            return 1
        fi
    done
    success "Required files present"
}

# Check for compilation errors
check_compilation() {
    log "Checking for compilation errors..."

    # Try to check compilation
    if godot --headless --check-only "$GODOT_PROJECT" 2>&1; then
        success "No compilation errors detected"
    else
        error "Compilation errors found"
        return 1
    fi
}

# Validate scenes
validate_scenes() {
    log "Validating scenes..."

    # Check main scene
    local main_scene="$PROJECT_DIR/downtown/scenes/main.tscn"
    if [ ! -f "$main_scene" ]; then
        error "Main scene not found: $main_scene"
        return 1
    fi

    # Try to load main scene
    if godot --headless --scene "$main_scene" --quit 2>&1 | grep -q "ERROR\|error"; then
        error "Scene loading errors detected"
        return 1
    else
        success "Main scene loads successfully"
    fi
}

# Run automated tests
run_tests() {
    log "Running automated tests..."

    local test_script="$PROJECT_DIR/downtown/scripts/test_suite.gd"
    if [ ! -f "$test_script" ]; then
        warning "Test suite not found: $test_script"
        return 0
    fi

    if godot --headless --script "$test_script" 2>&1; then
        success "All tests passed"
    else
        error "Test failures detected"
        return 1
    fi
}

# Check resource files
validate_resources() {
    log "Validating resource files..."

    local data_dir="$PROJECT_DIR/downtown/data"
    local required_data_files=("buildings.json" "resources.json")

    for file in "${required_data_files[@]}"; do
        if [ ! -f "$data_dir/$file" ]; then
            error "Required data file missing: $file"
            return 1
        fi
    done
    success "All required data files present"
}

# Performance check
performance_check() {
    log "Running performance checks..."

    # This would require running the game briefly and monitoring performance
    # For now, just check that the project can start
    warning "Performance checks not fully implemented yet"
    # Future: Implement actual performance monitoring
}

# Generate validation report
generate_report() {
    log "Generating validation report..."

    local error_count=$(grep -c "ERROR" "$LOG_FILE" 2>/dev/null || echo "0")
    local warning_count=$(grep -c "WARNING" "$LOG_FILE" 2>/dev/null || echo "0")

    echo ""
    echo "========================================="
    echo "📊 Validation Report"
    echo "========================================="
    echo "Project: Downtown City Management Game"
    echo "Date: $(date)"
    echo "Errors: $error_count"
    echo "Warnings: $warning_count"
    echo "Log file: $LOG_FILE"
    echo ""

    if [ "$error_count" -eq 0 ]; then
        echo -e "${GREEN}🎉 All validations passed!${NC}"
        echo "Status: READY FOR BUILD"
    else
        echo -e "${RED}❌ Validation failed with $error_count errors${NC}"
        echo "Status: BUILD BLOCKED"
        return 1
    fi
}

# Main execution
main() {
    log "Starting Downtown validation pipeline"

    local exit_code=0

    # Run all validation steps
    check_godot || exit_code=1
    validate_project_structure || exit_code=1
    validate_resources || exit_code=1
    check_compilation || exit_code=1
    validate_scenes || exit_code=1
    run_tests || exit_code=1
    performance_check || exit_code=1

    generate_report || exit_code=1

    log "Validation pipeline complete"
    return $exit_code
}

# Run main function
main "$@"