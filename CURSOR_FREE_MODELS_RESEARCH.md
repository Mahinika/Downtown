# Comprehensive Research: Free Models Available in Cursor IDE

**Research Date:** January 15, 2026  
**Last Updated:** Based on documentation and community reports as of early 2026

---

## ⚠️ Important Disclaimer

Cursor IDE's model availability and free model status can change frequently. The information below is compiled from official documentation, forum posts, and user reports. **Always verify in your Cursor IDE settings** which models are currently marked as free (showing "0 requests/message" or similar indicators).

---

## ✅ CONFIRMED FREE MODELS (Don't Consume Premium Request Credits)

These models are officially documented and consistently reported as **free** (0 requests/message) in Normal Mode:

### 1. **Cursor Small**
- **Provider:** Cursor (Anysphere)
- **Status:** Always free, base model
- **Context Window:** 60k tokens
- **Notes:** Basic coding assistance, always available
- **Sources:** Official Cursor documentation, confirmed in forums

### 2. **DeepSeek V3** & **DeepSeek V3.1**
- **Provider:** DeepSeek / Fireworks
- **Status:** Free in Normal Mode
- **Features:** Agent-capable, supports advanced coding tasks
- **Notes:** Both V3 and V3.1 variants are free
- **Sources:** Official docs, forum confirmations (Aug 2025)

### 3. **Gemini 2.5 Flash**
- **Provider:** Google / Gemini
- **Status:** Free in Normal Mode, non-premium
- **Context Window:** 1M tokens (very large)
- **Notes:** Excellent for large codebases due to huge context window
- **Sources:** Official documentation, forum posts (Sept 2025)

### 4. **GPT-4o Mini**
- **Provider:** OpenAI
- **Status:** Free in Normal Mode
- **Daily Limit:** 500 requests/day on free plan (may be higher/lifted on Pro+)
- **Notes:** Smaller, faster version of GPT-4o, good for basic tasks
- **Sources:** Official docs, user reports

### 5. **Grok 3 Mini** (also listed as **Grok 3-mini-beta**)
- **Provider:** xAI
- **Status:** Free in Normal Mode, non-premium
- **Notes:** Lightweight version of Grok models
- **Sources:** Forum confirmations, model listings

### 6. **Grok Code Fast 1** (also **grok-code-fast-1**)
- **Provider:** xAI / Cursor
- **Status:** Currently free (extended trial as of Nov 2025)
- **Launch Date:** August 26, 2025
- **Notes:** 
  - Initially free for 1 week, then extended "until further notice"
  - Some users report it's currently the only model guaranteed always free for Pro users
  - Performance may vary for complex tasks
  - Future pricing (if/when free period ends): $0.20/$1.50 per million tokens (input/output)
- **Regional Note:** Some reports suggest availability may differ outside US
- **Sources:** Forum announcements (Nov 2025), community reports

---

## ⚠️ MODELS WITH UNCERTAIN STATUS

These models are reported as free by some users, but status may vary by plan, region, or recent changes:

### 7. **GPT-5 Mini** & **GPT-5 Nano**
- **Status:** Mixed reports
- **Details:** 
  - Some users report these as free (Dec 2025)
  - Official documentation suggests they may consume credits
  - May have been free during promotional periods
- **Recommendation:** Check your account settings to verify current status

### 8. **DeepSeek R1**
- **Status:** Uncertain
- **Details:** Mentioned in some documentation but free status unclear
- **Recommendation:** Verify in model settings

---

## 📊 How Free Models Work

### What "Free" Means:
- **0 requests/message** - Does NOT consume your "fast premium request" quota
- **Unlimited usage** (or very high limits) on free models
- Available even after exhausting premium request credits

### Important Distinctions:

#### **Normal Mode vs Max Mode vs Agent Mode:**
- Free models are typically free in **Normal Mode**
- Using **Max Mode** (larger context windows) may incur costs
- **Agent Mode** with tool calls may consume credits even for free models

#### **Fast vs Slow Requests:**
- **Fast requests:** Priority handling, immediate responses (limited quota)
- **Slow requests:** Lower priority, may be delayed (unlimited but slower)
- Free models typically avoid slow queue issues

---

## 💰 Plan Comparison: Free Model Access

### **Hobby/Free Plan:**
- ✅ Access to all free models
- ⚠️ Some models have usage caps (e.g., GPT-4o mini: 500 requests/day)
- 📊 ~500 free-model requests/month included
- 📊 ~50 fast premium requests/month

### **Pro Plan ($20/month):**
- ✅ Same free models as Free plan
- ✅ Higher or unlimited free model usage
- 📊 500 fast premium requests/month included
- ✅ Unlimited tab completions

### **Pro+ Plan ($60/month):**
- ✅ All free models available
- ✅ 3× usage on premium models (compared to Pro)
- 📊 ~$70 worth of included API agent usage
- ✅ Higher priority in queues

### **Ultra Plan ($200/month):**
- ✅ All free models available
- ✅ 20× usage on premium models
- 📊 ~$400 worth of included API agent usage
- ✅ Priority access to new features

---

## ⚠️ Caveats & Limitations

### 1. **Model Status Can Change:**
- Cursor frequently updates which models are free
- Check official docs or your account settings regularly
- What's free today may not be free tomorrow

### 2. **Regional Variations:**
- Some models may have different availability by region
- Grok Code Fast reported to potentially vary outside US

### 3. **Mode-Specific Costs:**
- **Normal Mode:** Free models are typically 0 cost
- **Max Mode:** May incur token-based pricing even for "free" models
- **Agent Mode:** Tool calls may consume credits

### 4. **Auto Mode Behavior:**
- Using "Auto" mode may select premium models automatically
- To guarantee free model usage, manually select the model

### 5. **Performance Tradeoffs:**
- Free models may be slower or have fewer capabilities
- Generally suitable for basic to moderate coding tasks
- Premium models recommended for complex/large codebases

---

## 🔍 How to Verify Free Models in Your Account

### Method 1: Check Model Settings
1. Open Cursor IDE Settings
2. Navigate to "Models" or "AI Models"
3. Look for indicators showing "0 requests/message" or "Free"
4. Models marked as free won't consume premium request credits

### Method 2: Check Documentation
- Official docs: `docs.cursor.com/models`
- Check model pricing page for current status

### Method 3: Test Usage
- Monitor your usage dashboard after using a model
- Free models shouldn't increase "fast premium request" usage

---

## 📋 Summary Table: Free Models

| Model Name | Provider | Status | Context Window | Notes |
|-----------|----------|--------|----------------|-------|
| **Cursor Small** | Cursor | ✅ Always Free | 60k tokens | Base model |
| **DeepSeek V3** | DeepSeek | ✅ Free | - | Agent-capable |
| **DeepSeek V3.1** | DeepSeek | ✅ Free | - | Agent-capable |
| **Gemini 2.5 Flash** | Google | ✅ Free | 1M tokens | Huge context |
| **GPT-4o Mini** | OpenAI | ✅ Free* | - | *500/day limit on free plan |
| **Grok 3 Mini** | xAI | ✅ Free | - | Lightweight |
| **Grok Code Fast 1** | xAI | ✅ Free (trial) | - | Extended trial, check status |
| **GPT-5 Mini** | OpenAI | ⚠️ Uncertain | - | Verify in account |
| **GPT-5 Nano** | OpenAI | ⚠️ Uncertain | - | Verify in account |

---

## 🔗 Official Sources & References

### Official Documentation:
- Cursor Models Documentation: `docs.cursor.com/models`
- Cursor Pricing: `cursor.com/pricing`
- Account Usage: `docs.cursor.com/en/account/usage`

### Community Resources:
- Cursor Forum: `forum.cursor.com`
- Reddit r/cursor: Community discussions and updates

### Recent Announcements:
- Grok Code Fast launch (Aug 2025): `forum.cursor.com/t/grok-code-is-now-available`
- Free model confirmations (Sept 2025): `forum.cursor.com/t/are-there-still-free-models`
- Model availability updates: Check forum regularly

---

## 📝 Recommendations

1. **Verify Regularly:** Check your Cursor settings periodically for model status updates
2. **Use Normal Mode:** Free models are guaranteed free in Normal Mode
3. **Manual Selection:** Select free models manually rather than using "Auto" mode if you want to ensure no credit consumption
4. **Monitor Usage:** Check your usage dashboard to confirm models aren't consuming credits
5. **Stay Updated:** Follow Cursor's official announcements for model availability changes

---

## 🎯 Best Practices for Free Model Usage

### When to Use Free Models:
- ✅ Basic coding tasks and small scripts
- ✅ Simple refactoring
- ✅ Code completion (tab completions)
- ✅ Learning and experimentation
- ✅ High-volume, lower-complexity tasks

### When to Use Premium Models:
- ✅ Large codebase refactoring
- ✅ Complex multi-file changes
- ✅ Advanced debugging
- ✅ Architecture-level decisions
- ✅ Tasks requiring very large context windows

---

**Note:** This document is based on research compiled on January 15, 2026. Model availability and pricing are subject to change. Always verify current status in your Cursor IDE account settings.
