# API Configuration

## OpenRouter API Key

Your OpenRouter API key is stored in `openrouter.json` (excluded from git for security).

## Using in Cursor

To configure Cursor to use the NVIDIA Nemotron model via OpenRouter:

1. **Open Cursor Settings:**
   - Press `Ctrl+,` (or `Cmd+,` on Mac)
   - Or go to File → Preferences → Settings

2. **Configure AI Model:**
   - Look for "AI" or "Model" settings
   - If Cursor supports custom API endpoints, configure:
     - API Endpoint: `https://openrouter.ai/api/v1/chat/completions`
     - API Key: Use the key from `config/openrouter.json`
     - Model: `nvidia/nemotron-3-nano-30b-a3b:free`

3. **Alternative: Environment Variable**
   - You can also set the API key as an environment variable:
     ```bash
     export OPENROUTER_API_KEY="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"
     ```

## Using in Code

If you want to use this API key in your project code:

```gdscript
# Example: Load API key from config
var config_file = FileAccess.open("res://config/openrouter.json", FileAccess.READ)
if config_file:
    var json = JSON.new()
    var parse_result = json.parse(config_file.get_as_text())
    config_file.close()
    
    if parse_result == OK:
        var config = json.data
        var api_key = config.get("api_key", "")
        var model = config.get("model", "")
```

## Security Note

⚠️ **Never commit API keys to version control!** The `config/openrouter.json` file is already in `.gitignore`.
