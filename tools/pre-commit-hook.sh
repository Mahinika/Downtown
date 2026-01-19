#!/bin/bash
# Pre-commit hook for GDScript validation
# Install: Copy to .git/hooks/pre-commit or run: npm run install:hooks

echo "Running GDScript validation..."

# Run validation script
npm run validate

# Exit with validation result
if [ $? -ne 0 ]; then
  echo ""
  echo "❌ Pre-commit validation failed!"
  echo "Fix the errors above before committing."
  echo ""
  echo "To skip validation (not recommended):"
  echo "  git commit --no-verify"
  exit 1
fi

echo "✅ Pre-commit validation passed"
exit 0
