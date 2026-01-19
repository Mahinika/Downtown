# Development Tools

Tools and scripts to help reduce coding errors and maintain code quality.

## GDScript Validation

Automated validation script that checks for common error patterns documented in `memory-bank/Downtown/error-patterns.md`.

### Usage

```bash
# Quick validation (shows errors and warnings)
npm run validate

# Verbose mode (includes suggestions)
npm run validate:verbose
```

### What It Checks

- **Critical Errors**:
  - Lambda functions in signal connections (Pattern 1)
  - Deprecated API usage (Pattern 15)

- **Warnings**:
  - Strict typing on Autoload references (Pattern 2)
  - Generic max/min/clamp functions (Pattern 4)
  - Unsafe node access patterns

- **Suggestions** (verbose mode):
  - Missing type hints
  - Missing return type hints
  - Error messages without context

### Exit Codes

- `0` - Validation passed (may have warnings)
- `1` - Validation failed (critical errors found)

## Pre-commit Hooks

Automatically validate code before each commit.

### Installation

```bash
npm run install:hooks
```

This installs a pre-commit hook that runs validation before each commit. If validation fails, the commit is blocked.

### Skip Validation (Not Recommended)

```bash
git commit --no-verify
```

## Code Review Checklist

See `tools/code-review-checklist.md` for a comprehensive checklist based on documented error patterns.

## Editor Configuration

### VS Code

Recommended extensions (see `.vscode/extensions.json`):
- `geequlim.gdscript` - GDScript language support
- `razoric.gdscript-toolkit` - Additional GDScript tools

Settings are configured in `.vscode/settings.json` for:
- GDScript formatting
- File associations
- LSP configuration

### EditorConfig

EditorConfig settings in `downtown/.editorconfig`:
- Tab indentation (4 spaces)
- UTF-8 encoding
- Line length limits
- Trailing whitespace removal

## Error Patterns Reference

All error patterns are documented in:
- `memory-bank/Downtown/error-patterns.md`

Current patterns documented: 16

## Integration with CI/CD

The validation script can be integrated into CI/CD pipelines:

```bash
# In CI script
npm run validate
if [ $? -ne 0 ]; then
  echo "Validation failed!"
  exit 1
fi
```

## Contributing

When adding new error patterns:

1. Document the pattern in `memory-bank/Downtown/error-patterns.md`
2. Add a check to `tools/validate-gdscript.js` if it can be automatically detected
3. Update `tools/code-review-checklist.md` with the new pattern
