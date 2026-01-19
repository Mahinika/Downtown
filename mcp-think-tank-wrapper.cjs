#!/usr/bin/env node
/**
 * Wrapper script to fix Windows path issue with mcp-think-tank
 * Converts Windows paths to file:// URLs before importing
 */

const path = require('path');
const fs = require('fs');
const { pathToFileURL } = require('url');

// Try multiple possible locations for the server module
const possiblePaths = [
  // Local node_modules (relative to wrapper location)
  path.join(__dirname, 'node_modules/mcp-think-tank/dist/src/server.js'),
  // Global npm installation (Windows)
  path.join(process.env.APPDATA || '', 'npm/node_modules/mcp-think-tank/dist/src/server.js'),
  // Global npm installation (Unix/Mac fallback)
  path.join(process.env.HOME || '', '.npm-global/lib/node_modules/mcp-think-tank/dist/src/server.js'),
  // Alternative global location
  path.join(process.env.ProgramFiles || '', 'nodejs/node_modules/mcp-think-tank/dist/src/server.js'),
];

// Find the first existing path
let actualServerPath = null;
for (const testPath of possiblePaths) {
  try {
    if (fs.existsSync(testPath)) {
      actualServerPath = testPath;
      break;
    }
  } catch (e) {
    // Continue to next path
  }
}

if (!actualServerPath) {
  console.error('Error: Could not find mcp-think-tank server module in any of the following locations:');
  possiblePaths.forEach(p => console.error(`  - ${p}`));
  process.exit(1);
}

// Convert Windows path to file:// URL (required for ESM imports on Windows)
const serverUrl = pathToFileURL(actualServerPath).href;

// Launch the server using the dynamic import() function
(async function() {
  try {
    // Import the server module - it has top-level code that will run
    // This import() with file:// URL works on Windows
    await import(serverUrl);
    // The server will continue running via its top-level code
  } catch (e) {
    console.error(`Failed to start MCP Think Tank server:`, e);
    process.exit(1);
  }
})();