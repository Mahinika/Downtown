# Fix: "GPT-4o Mini does not work with your current plan or api key" Error

## 🔍 Why This Happens

Even though GPT-4o Mini is a "free" model, Cursor IDE requires one of these configurations:

1. **Using Cursor's Built-in API** (no custom API key needed)
2. **Using Your Own OpenAI API Key** with manual model configuration
3. **Model Not Manually Added** - Known bug where the model disappears after adding custom API keys

---

## ✅ Solution 1: Check If You're Using a Custom API Key

If you've added a **custom OpenAI API key** in Cursor settings, GPT-4o Mini may not appear automatically.

### Steps to Fix:

1. **Open Cursor Settings**
   - Click the gear icon or press `Ctrl+,` (Windows)

2. **Navigate to Models Section**
   - Go to **Settings → Models** (or **Settings → AI Models**)

3. **Check Your API Key Status**
   - Look for "OpenAI API Key" section
   - If you have a key entered, this is likely the cause

4. **Manually Add GPT-4o Mini**:
   - In the Models list, click **"+ Add model"** or **"Add Custom Model"**
   - Type exactly: `gpt-4o-mini` (lowercase with hyphens)
   - Save/Confirm

5. **Verify the Model Appears**
   - GPT-4o Mini should now be available in your model dropdown

---

## ✅ Solution 2: Remove Custom API Key (Use Cursor's Built-in)

If you don't need to use your own API key:

1. **Go to Settings → Models**
2. **Find "OpenAI API Key" section**
3. **Remove/Clear the API key**
4. **Click Save**
5. **Restart Cursor IDE**
6. **GPT-4o Mini should appear automatically** using Cursor's built-in API

**Note:** With Pro+ plan, you get $70 of included API usage, so you may not need your own key for GPT-4o Mini.

---

## ✅ Solution 3: Verify Your Pro+ Subscription Status

1. **Check Your Billing Status**:
   - Go to **Settings → Account** or **Settings → Billing**
   - Confirm you're on **Pro+** plan ($60/month)

2. **If Not Active**:
   - Go to `cursor.com` and verify your subscription
   - Make sure payment method is valid

3. **Sync Account**:
   - In Cursor, go to **Settings → Account**
   - Click **"Refresh"** or **"Sync Account"** if available
   - Restart Cursor

---

## ✅ Solution 4: Update Cursor IDE

Sometimes this error is fixed in newer versions:

1. **Check for Updates**:
   - Go to **Help → Check for Updates** (or similar)
   - Or download latest from `cursor.com`

2. **Restart After Update**:
   - Close Cursor completely
   - Reopen and try GPT-4o Mini again

---

## ✅ Solution 5: Verify Model Availability in Settings

1. **Open Settings → Models**
2. **Look for GPT-4o Mini** in the model list
3. **Check if it shows**:
   - ✅ "Free" or "0 requests/message"
   - ❌ If it's missing, use Solution 1 to add it manually
   - ❌ If it shows as "Premium" or requires payment, contact Cursor support

---

## 🔧 Alternative: Use Other Free Models

While fixing GPT-4o Mini, you can use these **confirmed free models** that should work without issues:

1. **Cursor Small** - Always available
2. **Gemini 2.5 Flash** - Very large context window (1M tokens)
3. **Grok 3 Mini** - Usually works without API key issues
4. **Grok Code Fast 1** - Currently in extended free trial
5. **DeepSeek V3 / V3.1** - Agent-capable

---

## 🐛 Known Bugs & Issues

### Bug 1: Model Disappears After Adding API Key
- **Symptom:** GPT-4o Mini was visible, but disappeared after adding custom OpenAI API key
- **Fix:** Manually add `gpt-4o-mini` using "+ Add model" (Solution 1)

### Bug 2: Error Persists Despite Pro+ Plan
- **Symptom:** Error shows even with active Pro+ subscription
- **Possible Causes:**
  - Account not synced properly
  - Custom API key conflict
  - Regional availability issue

---

## 📞 If Nothing Works

If you've tried all solutions and still get the error:

1. **Contact Cursor Support**:
   - Email: support@cursor.com
   - Forum: `forum.cursor.com`
   - Include:
     - Your plan type (Pro+)
     - Whether you're using a custom API key
     - Your Cursor version
     - Screenshot of the error

2. **Check Cursor Status**:
   - Visit `status.cursor.com` for service issues
   - Check `forum.cursor.com` for known issues

3. **Temporary Workaround**:
   - Use other free models (Gemini 2.5 Flash, Grok 3 Mini, Cursor Small)
   - These should work without API key issues

---

## 📋 Quick Checklist

- [ ] I've checked if I'm using a custom OpenAI API key
- [ ] I've manually added `gpt-4o-mini` in Settings → Models
- [ ] I've verified my Pro+ subscription is active
- [ ] I've updated Cursor to the latest version
- [ ] I've restarted Cursor after making changes
- [ ] I've checked Settings → Models for GPT-4o Mini availability
- [ ] If all fails, I've contacted Cursor support

---

## 💡 Pro Tips

1. **Use Gemini 2.5 Flash as Alternative**:
   - It's also free and has a huge 1M token context window
   - Often more reliable than GPT-4o Mini
   - Doesn't require custom API key setup

2. **Keep Cursor's Built-in API for Free Models**:
   - If you only need free models, don't add custom API keys
   - Cursor's built-in API handles free models seamlessly

3. **Use Custom API Keys Only for Premium Models**:
   - Add your API key only if you need premium models (GPT-4, Claude Sonnet, etc.)
   - For free models, let Cursor handle the API calls

---

**Last Updated:** January 15, 2026  
**Based on:** Official Cursor documentation and community reports
