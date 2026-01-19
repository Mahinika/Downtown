#!/usr/bin/env node
/**
 * GDScript Validation Script
 * Checks for common error patterns documented in error-patterns.md
 */

import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
import { dirname } from 'path';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

const ERROR_PATTERNS = {
  // Pattern 1: Lambda Capture Errors in Signal Connections
  lambdaInSignal: {
    pattern: /\.connect\s*\(\s*["'][^"']+["']\s*,\s*func\s*\(/g,
    message: '❌ Lambda in signal connection (Pattern 1) - Use named methods instead',
    severity: 'CRITICAL'
  },
  
  // Pattern 2: Circular Dependency - Strict typing on Autoloads
  strictAutoloadType: {
    pattern: /var\s+(\w+):\s*(\w+Manager|DataManager|ResourceManager|BuildingManager|CityManager|VillagerManager|JobSystem|EventManager|ResearchManager|ProgressionManager|SkillManager|SeasonalManager|SaveManager|UITheme|Logger)\s*=/g,
    message: '⚠️  Strict typing on Autoload reference (Pattern 2) - May cause circular dependencies',
    severity: 'HIGH',
    exclude: ['extends', 'func', 'const']
  },
  
  // Pattern 4: Type Inference Errors - Generic functions
  genericMaxMin: {
    pattern: /\b(max|min|clamp)\s*\(/g,
    message: '⚠️  Generic max/min/clamp (Pattern 4) - Use maxi/mini/clampi or maxf/minf/clampf for explicit types',
    severity: 'MEDIUM'
  },
  
  // Pattern 15: Deprecated rect_min_size
  deprecatedRectMinSize: {
    pattern: /\.rect_min_size\s*=/g,
    message: '❌ Deprecated rect_min_size (Pattern 15) - Use custom_minimum_size instead',
    severity: 'MEDIUM'
  },
  
  // Missing type hints on variables
  missingTypeHint: {
    pattern: /var\s+(\w+)\s*=\s*(?!["'])/g,
    message: '💡 Consider adding type hint for better error detection',
    severity: 'LOW',
    exclude: ['extends', 'func', 'const', 'if', 'for', 'while', 'match']
  },
  
  // Missing return type hints
  missingReturnType: {
    pattern: /func\s+(\w+)\s*\([^)]*\)\s*(?!->)/g,
    message: '💡 Consider adding return type hint (-> void, -> bool, etc.)',
    severity: 'LOW',
    exclude: ['_ready', '_process', '_physics_process', '_input', '_unhandled_input']
  },
  
  // Using push_warning without context
  barePushWarning: {
    pattern: /push_warning\s*\(\s*["'][^"']+["']\s*\)/g,
    message: '💡 Consider adding [ClassName] prefix to push_warning for better debugging',
    severity: 'LOW'
  },
  
  // Potential null access without check
  unsafeNodeAccess: {
    pattern: /\$\w+\.[\w.]+(?!\?)/g,
    message: '⚠️  Consider using get_node_or_null() and null checks for safer node access',
    severity: 'MEDIUM',
    exclude: ['$', 'get_node_or_null', 'is_instance_valid']
  }
};

const IGNORE_PATTERNS = [
  /node_modules/,
  /\.godot/,
  /\.cache/,
  /\.import/
];

let errors = [];
let warnings = [];
let suggestions = [];

function shouldIgnoreFile(filePath) {
  return IGNORE_PATTERNS.some(pattern => pattern.test(filePath));
}

function checkFile(filePath) {
  if (shouldIgnoreFile(filePath)) {
    return;
  }
  
  const content = fs.readFileSync(filePath, 'utf8');
  const lines = content.split('\n');
  
  Object.entries(ERROR_PATTERNS).forEach(([patternName, patternData]) => {
    const matches = [...content.matchAll(patternData.pattern)];
    
    matches.forEach(match => {
      const lineNumber = content.substring(0, match.index).split('\n').length;
      const line = lines[lineNumber - 1]?.trim() || '';
      
      // Skip if line matches exclude patterns
      if (patternData.exclude && patternData.exclude.some(ex => line.includes(ex))) {
        return;
      }
      
      const issue = {
        file: path.relative(process.cwd(), filePath),
        line: lineNumber,
        pattern: patternName,
        message: patternData.message,
        severity: patternData.severity,
        code: line.substring(0, 80)
      };
      
      if (patternData.severity === 'CRITICAL') {
        errors.push(issue);
      } else if (patternData.severity === 'HIGH' || patternData.severity === 'MEDIUM') {
        warnings.push(issue);
      } else {
        suggestions.push(issue);
      }
    });
  });
}

function findGDScriptFiles(dir) {
  const files = [];
  
  function traverse(currentDir) {
    const entries = fs.readdirSync(currentDir, { withFileTypes: true });
    
    for (const entry of entries) {
      const fullPath = path.join(currentDir, entry.name);
      
      if (shouldIgnoreFile(fullPath)) {
        continue;
      }
      
      if (entry.isDirectory()) {
        traverse(fullPath);
      } else if (entry.name.endsWith('.gd')) {
        files.push(fullPath);
      }
    }
  }
  
  traverse(dir);
  return files;
}

function main() {
  const scriptDir = __dirname;
  const projectRoot = path.resolve(scriptDir, '..');
  const downtownDir = path.join(projectRoot, 'downtown');
  
  if (!fs.existsSync(downtownDir)) {
    console.error('❌ downtown/ directory not found');
    process.exit(1);
  }
  
  console.log('🔍 Validating GDScript files...\n');
  
  const files = findGDScriptFiles(downtownDir);
  console.log(`Found ${files.length} GDScript files\n`);
  
  files.forEach(checkFile);
  
  // Print results
  if (errors.length > 0) {
    console.log('❌ CRITICAL ERRORS:');
    errors.forEach(err => {
      console.log(`  ${err.file}:${err.line} - ${err.message}`);
      console.log(`    ${err.code}`);
    });
    console.log();
  }
  
  if (warnings.length > 0) {
    console.log('⚠️  WARNINGS:');
    warnings.forEach(warn => {
      console.log(`  ${warn.file}:${warn.line} - ${warn.message}`);
      console.log(`    ${warn.code}`);
    });
    console.log();
  }
  
  if (suggestions.length > 0 && process.argv.includes('--verbose')) {
    console.log('💡 SUGGESTIONS:');
    suggestions.forEach(sugg => {
      console.log(`  ${sugg.file}:${sugg.line} - ${sugg.message}`);
    });
    console.log();
  }
  
  // Summary
  console.log('📊 Summary:');
  console.log(`  Files checked: ${files.length}`);
  console.log(`  Critical errors: ${errors.length}`);
  console.log(`  Warnings: ${warnings.length}`);
  if (process.argv.includes('--verbose')) {
    console.log(`  Suggestions: ${suggestions.length}`);
  }
  console.log();
  
  // Exit code
  if (errors.length > 0) {
    console.log('❌ Validation failed - fix critical errors before committing');
    process.exit(1);
  } else if (warnings.length > 0) {
    console.log('⚠️  Validation passed with warnings');
    process.exit(0);
  } else {
    console.log('✅ Validation passed');
    process.exit(0);
  }
}

// Run if executed directly
main();

export { checkFile, findGDScriptFiles, ERROR_PATTERNS };
