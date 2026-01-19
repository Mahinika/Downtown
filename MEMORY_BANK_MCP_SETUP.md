# Memory Bank MCP Server Setup Guide

## Installation Complete ✅

The Memory Bank MCP Server (`@allpepper/memory-bank-mcp`) has been installed globally via npm.

## Cursor Configuration

To enable the Memory Bank MCP Server in Cursor, follow these steps:

### Step 1: Open Cursor Settings
1. Open Cursor
2. Go to **Settings** (Ctrl+, or Cmd+,)
3. Navigate to **Features** → **MCP**

### Step 2: Add New MCP Server
1. Click the **"+ Add New MCP Server"** button
2. Configure with the following settings:

**Configuration:**
```json
{
  "memory-bank-mcp": {
    "command": "npx",
    "args": ["-y", "@allpepper/memory-bank-mcp"],
    "env": {
      "MEMORY_BANK_ROOT": "c:\\Users\\Ropbe\\Desktop\\Downtown\\memory-bank"
    },
    "disabled": false,
    "autoApprove": [
      "memory_bank_read",
      "memory_bank_write",
      "memory_bank_update",
      "list_projects",
      "list_project_files"
    ]
  }
}
```

### Step 3: Manual Configuration in Cursor UI

If you need to configure via the UI instead of JSON:

1. **Name**: `memory-bank-mcp`
2. **Type**: Select `stdio`
3. **Command**: `npx`
4. **Arguments**: `-y`, `@allpepper/memory-bank-mcp`
5. **Environment Variables**:
   - Key: `MEMORY_BANK_ROOT`
   - Value: `c:\Users\Ropbe\Desktop\Downtown\memory-bank`
6. **Auto-Approve**: Enable auto-approval for:
   - `memory_bank_read`
   - `memory_bank_write`
   - `memory_bank_update`
   - `list_projects`
   - `list_project_files`

### Step 4: Verify Installation

After adding the server:
1. Click the **refresh** button in the MCP servers list
2. You should see `memory-bank-mcp` in the list
3. The tools should appear in the tool list (you may need to expand the server entry)

## Available Tools

Once configured, the Memory Bank MCP Server provides these tools:

- **Initialize Memory Bank**: Set up memory bank structure for a project
- **Update Document**: Update or create memory bank documents
- **Query Memory Bank**: Search and query memory bank content
- **List Projects**: List all projects in the memory bank
- **List Project Files**: List files for a specific project
- **Analyze Project**: Analyze project summaries and suggest memory bank content

## Usage

The Memory Bank MCP Server works alongside your existing manual memory bank workflow:

- **Existing Workflow**: Continue reading memory bank files as defined in `.cursorrules`
- **MCP Tools**: Use for automated analysis, template generation, and programmatic updates
- **Best of Both**: Manual control + automated assistance

## Troubleshooting

### Server Not Appearing
- Verify `npx` is in your PATH: Run `npx --version` in terminal
- Check that `@allpepper/memory-bank-mcp` is accessible: Run `npx -y @allpepper/memory-bank-mcp --help`
- Restart Cursor after configuration changes

### Path Issues
- Use absolute paths for `MEMORY_BANK_ROOT`
- On Windows, use forward slashes or escaped backslashes: `c:\\Users\\...` or `c:/Users/...`
- Ensure the path points to your existing `memory-bank` directory

### Tools Not Available
- Click the refresh button in MCP settings
- Verify the server shows as "Connected" or "Running"
- Check Cursor's developer console for MCP errors

## Integration with Existing Memory Bank

Your existing memory bank files in `memory-bank/` will work seamlessly with the MCP server:

- ✅ All existing files are preserved
- ✅ The MCP server reads/writes to the same directory
- ✅ Your `.cursorrules` workflow continues to work
- ✅ MCP tools provide additional automation capabilities

## Next Steps

After configuration:
1. Test by asking the AI to "analyze the project and update the memory bank"
2. Try template generation for new features
3. Use automated content suggestions during development
4. Combine MCP tools with your existing manual workflow for best results

## Current Project State

The project is currently in an active development phase. Key components include:

- **Godot MCP Bridge**: Successfully moved and integrated into the project structure.
- **Building System**: Reworked and marked as complete.
- **Game Pipeline**: Analyzed and tested, with results documented.
- **Extensions**: Installation guide provided and implemented.
- **Visual Identity**: Implemented and documented.

## Recent Updates

- **Godot MCP Tools**: Updated and tested, with enhancements summarized.
- **Memory Bank**: Suggestions for updates provided and partially implemented.
- **Performance**: Regression tests and monitoring systems in place.

---

**Last Updated**: January 2026
**Installation Date**: $(date)
**Package Version**: @allpepper/memory-bank-mcp (latest)
**Project Status**: Active Development
