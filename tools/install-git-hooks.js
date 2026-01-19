#!/usr/bin/env node
/**
 * Install Git Hooks
 * Sets up pre-commit validation hook
 */

import fs from 'fs';
import path from 'path';
import os from 'os';
import { fileURLToPath } from 'url';
import { dirname } from 'path';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);
const scriptDir = __dirname;
const projectRoot = path.resolve(scriptDir, '..');
const gitHooksDir = path.join(projectRoot, '.git', 'hooks');

function main() {
  // Check if .git directory exists
  if (!fs.existsSync(path.join(projectRoot, '.git'))) {
    console.log('⚠️  .git directory not found. This project may not be a git repository.');
    console.log('   Run "git init" first if you want to use git hooks.');
    process.exit(0);
  }
  
  // Create hooks directory if it doesn't exist
  if (!fs.existsSync(gitHooksDir)) {
    fs.mkdirSync(gitHooksDir, { recursive: true });
  }
  
  // Determine which hook script to use based on OS
  const isWindows = os.platform() === 'win32';
  const hookScript = isWindows 
    ? path.join(scriptDir, 'pre-commit-hook.ps1')
    : path.join(scriptDir, 'pre-commit-hook.sh');
  
  const hookTarget = path.join(gitHooksDir, 'pre-commit');
  
  // Read the hook script
  let hookContent = fs.readFileSync(hookScript, 'utf8');
  
  // For Windows, we need to create a batch file that calls PowerShell
  if (isWindows) {
    const batchContent = `@echo off
powershell.exe -ExecutionPolicy Bypass -File "${hookScript}" %*
if errorlevel 1 exit 1
`;
    fs.writeFileSync(hookTarget, batchContent);
    // Also create PowerShell version
    fs.writeFileSync(hookTarget + '.ps1', hookContent);
  } else {
    // For Unix-like systems, write the shell script
    fs.writeFileSync(hookTarget, hookContent);
    // Make it executable
    fs.chmodSync(hookTarget, '755');
  }
  
  console.log('✅ Git hooks installed successfully!');
  console.log(`   Pre-commit hook: ${hookTarget}`);
  console.log('');
  console.log('The pre-commit hook will now run validation before each commit.');
  console.log('To skip validation (not recommended): git commit --no-verify');
}

// Run if executed directly
main();

export { main };
