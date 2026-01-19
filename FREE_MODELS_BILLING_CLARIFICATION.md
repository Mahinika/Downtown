# Free Models Billing Clarification - Important Correction

**Date:** January 16, 2026  
**Based on:** Actual usage logs and billing behavior

---

## ⚠️ Important Correction to Previous Information

I need to correct an earlier statement: **"Free models" in Cursor IDE are NOT completely free when usage-based pricing (On-Demand) is enabled.**

---

## 🔍 What "Free Models" Actually Means

### What "Free" Means:
- ✅ **Don't consume your "fast premium request" quota** (0 requests/message)
- ✅ **Work even when you have 0 requests left** in your quota
- ✅ **Available without exhausting your included usage first**

### What "Free" Does NOT Mean:
- ❌ **NOT free from token-based billing** when On-Demand/Usage-Based Pricing is enabled
- ❌ **NOT free from charges** if you have usage-based pricing active
- ❌ **Will still be billed per token** (just at very low rates)

---

## 💰 How Free Models Are Actually Billed

Based on your usage log, here's what's happening:

### Example Usage (From Your Log):

| Model | Type | Tokens | Cost |
|-------|------|--------|------|
| **gemini-2.5-flash** | On-Demand | 43.3K | $0.01 |
| **gpt-4o-mini** | On-Demand | 49.8K | <$0.01 |
| **auto** | Included | 186.6K | $0.16 (Included) |

### Key Observations:

1. **"On-Demand" Usage:**
   - `gemini-2.5-flash` and `gpt-4o-mini` show as "On-Demand"
   - They are being charged per token (very cheap: ~$0.01 per ~43K tokens)
   - This happens when usage-based pricing is enabled

2. **"Included" Usage:**
   - `auto` model shows as "Included"
   - Uses your included quota ($70/month on Pro+)
   - Doesn't incur extra charges beyond your plan

---

## 📊 Two Different Billing Systems

### 1. **Request-Based Billing** (Premium Models)
- Consumes your "fast premium request" quota
- 1 request = 1 unit from your quota
- Free models: **0 requests/message** ✅

### 2. **Token-Based Billing** (All Models with On-Demand)
- Charges per token used
- Applies when usage-based pricing is enabled
- Free models: **Still charged per token** ❌ (but very cheap)

---

## 🔧 Why You're Seeing Charges

### If Usage-Based Pricing is Enabled:
- ✅ Free models **don't consume your request quota** (this part is free)
- ❌ Free models **still get charged per token** (this part costs money)
- The costs are very low (cents), but not zero

### If Usage-Based Pricing is Disabled:
- ✅ Free models work without charges
- ❌ But you'll hit limits and be moved to "slow pool"
- You may not be able to use premium models beyond your quota

---

## 💡 What This Means for You

### Current Situation (On-Demand Enabled):
- **Free models are available** even with 0 requests left ✅
- **Free models still cost money** per token (very cheap: ~$0.01 per 43K tokens) ❌
- **Cost is minimal** compared to premium models

### Cost Comparison:
- **Free models:** ~$0.01 per 43K-50K tokens (very cheap)
- **Premium models:** Much more expensive per token
- **Auto (Included):** Uses your $70/month included quota

---

## 🎯 Options Going Forward

### Option 1: Keep On-Demand Enabled (Current)
- ✅ Use free models anytime (even with 0 requests)
- ❌ Pay small token charges (~$0.01 per 43K tokens)
- ✅ Best for consistent usage

### Option 2: Disable On-Demand Usage
- ✅ Free models truly free (no token charges)
- ❌ Hit limits faster, may be moved to slow pool
- ❌ May not be able to use models after quota exhausted

### Option 3: Use "Auto" Mode with Included Quota
- ✅ Uses your $70/month included quota (Pro+)
- ✅ No extra charges within quota
- ❌ Limited to your monthly allocation

---

## 📝 Summary

**Previous Statement (INCORRECT):**
> "Free models don't require usage-based pricing and are completely free"

**Corrected Statement:**
> "Free models don't consume your request quota (0 requests/message), allowing you to use them even with 0 requests left. However, if usage-based pricing (On-Demand) is enabled, they will still be billed per token at very low rates (~$0.01 per 43K tokens)."

---

## 🔍 How to Check Your Settings

1. **Check Usage-Based Pricing Status:**
   - Go to **Settings → Account → Billing**
   - Look for "Usage-Based Pricing" or "On-Demand Usage" toggle
   - If enabled, you'll see token-based charges

2. **Check Your Usage:**
   - Go to **Settings → Account → Usage**
   - Look for "On-Demand" vs "Included" entries
   - "On-Demand" = charged per token
   - "Included" = uses your monthly quota

3. **To Truly Use Free Models for Free:**
   - Disable "Usage-Based Pricing" / "On-Demand Usage"
   - Use models that show "0 requests/message"
   - Be aware you may hit rate limits

---

## ⚠️ Known Issues

From community reports:

1. **On-Demand Toggle Resetting:**
   - Some users report it turns back on automatically
   - Check settings regularly

2. **Billing Before Quota Exhausted:**
   - Known bug where On-Demand charges before using included quota
   - Cursor has acknowledged this bug (Oct 2025)

3. **Unclear Model Status:**
   - Some models show as "free" but still charge tokens
   - Check actual usage logs to see real costs

---

**Bottom Line:** Free models let you bypass request quotas, but with On-Demand enabled, you'll still pay small token charges. The costs are minimal, but not zero.
