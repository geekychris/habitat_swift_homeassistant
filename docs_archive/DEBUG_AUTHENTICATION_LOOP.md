# Debug Authentication Loop Issue

## How to Debug

### Step 1: Run with Console Open

1. Open project in Xcode
2. Run on simulator (Cmd+R)
3. **Open Console** (Cmd+Shift+Y or View → Debug Area → Show Debug Area)
4. **Filter console**: Type "🔐" or "✅" or "📝" in the filter box to see only our logs

### Step 2: Test the Authentication Flow

1. In the app, go to **Configuration** tab
2. Tap the **+** button
3. Fill in:
    - **Name**: Test
    - **Internal URL**: `http://192.168.1.100:8123` (your local URL)
    - **External URL**: `https://your-external.com` (your external URL - must be different!)
4. Select **"Web Login (OAuth)"**
5. Tap **"Save"**

### Step 3: Watch Console Output

You should see this sequence:

```
🔐 Starting OAuth2 flow for: http://192.168.1.100:8123
🌐 ASWebAuthView appeared for URL: http://192.168.1.100:8123
[Safari sheet appears - log in]
✅ Authentication successful
✅ Internal auth complete, token: eyJ0eXAiOiJKV1QiLCJh...
🔐 URLs differ - will open external auth after delay
🔐 Internal: http://192.168.1.100:8123
🔐 External: https://your-external.com
[0.5 second pause]
🔐 Starting OAuth2 flow for: https://your-external.com
🌐 ASWebAuthView appeared for URL: https://your-external.com
[Safari sheet appears again - log in]
✅ Authentication successful
✅ External auth complete, token: eyJ0eXAiOiJKV1QiLCJh...
💾 Saving both tokens - Internal: eyJ0eXAiOiJKV1Q..., External: eyJ0eXAiOiJKV1Q...
[0.3 second pause]
📝 saveConfiguration called
📝 Name: Test
📝 Internal Token: eyJ0eXAiOiJKV1QiLCJh...
📝 External Token: eyJ0eXAiOiJKV1QiLCJh...
📝 Calling viewModel.saveConfiguration...
📝 Setting as active configuration...
📝 Calling dismiss() to close form...
📝 dismiss() called - form should close now
```

**At this point, the form SHOULD close and you should be back at the config list.**

### Step 4: Check What Actually Happens

**If the form stays open:**

1. Copy the **entire console output**
2. Look for these key indicators:

**Check 1: Is saveConfiguration being called?**

```
Look for: "📝 saveConfiguration called"
```

- ✅ If YES: The callbacks are working
- ❌ If NO: The callbacks aren't reaching saveConfiguration

**Check 2: Is dismiss() being called?**

```
Look for: "📝 Calling dismiss() to close form..."
```

- ✅ If YES: dismiss() is being called
- ❌ If NO: Code isn't reaching the dismiss

**Check 3: Are there multiple auth cycles?**

```
Count how many times you see: "🔐 Starting OAuth2 flow"
```

- ✅ Should be 2 (internal + external)
- ❌ If 3+: Loop is happening

### Possible Issues and What to Look For

#### Issue 1: saveConfiguration Never Called

**Console shows:**

```
✅ External auth complete...
💾 Saving both tokens...
[Then nothing]
```

**Problem**: The callback isn't calling saveConfiguration

**Check**: Are there any Swift errors after "Saving both tokens"?

#### Issue 2: dismiss() Called But Form Doesn't Close

**Console shows:**

```
📝 Calling dismiss() to close form...
📝 dismiss() called - form should close now
[But form stays open]
```

**Problem**: Environment dismiss isn't working

**Possible causes:**

- Multiple sheets stacked
- Wrong dismiss environment
- Sheet state conflict

#### Issue 3: Authentication Repeats

**Console shows:**

```
✅ External auth complete...
💾 Saving both tokens...
📝 saveConfiguration called
📝 dismiss() called
🔐 Starting OAuth2 flow for: http://... [AGAIN!]
```

**Problem**: The form is being presented again

**Check**: Is the "Save" button somehow being triggered again?

### Step 5: Additional Debugging

If the issue isn't clear, add these checks:

**Check the sheet state:**

After external auth completes, check if:

```
showingWebAuth = false ✅ (should be false)
authStep = .none ✅ (should be .none)
```

**Check if form is still presented:**

The form should not be visible after dismiss() is called.

## Quick Test: Manual Token Entry

To verify the dismiss() works in general:

1. Configuration tab → Tap +
2. Fill in details
3. Select **"API Token"** (not OAuth)
4. Enter any token text
5. Tap "Save"

**Expected**: Form dismisses immediately

**If this works**: The dismiss() itself is fine, the issue is specific to the OAuth flow

**If this doesn't work**: There's a more fundamental issue with the form's dismiss

## What to Report

Please run the test and share:

1. **Complete console output** from start to when you tap Save again
2. **What you see on screen** at each step:
    - Does first Safari sheet appear?
    - Does it close after login?
    - Does second Safari sheet appear?
    - Does it close after login?
    - What screen are you left on?
3. **How many times** you see "🔐 Starting OAuth2 flow" in console
4. **Whether** you see "📝 dismiss() called" in console
5. **Whether** the form actually closes

## Expected vs Actual

### Expected Flow

```
Form (Enter details)
  ↓ Tap "Save"
Safari Sheet 1 (Internal login)
  ↓ Login success
Form briefly appears
  ↓ 0.5 sec
Safari Sheet 2 (External login)
  ↓ Login success
Form briefly appears
  ↓ 0.3 sec
Config List (Form closed) ✅
```

### If There's a Loop

```
Form (Enter details)
  ↓ Tap "Save"
Safari Sheet 1 (Internal login)
  ↓ Login success
Form appears
  ↓ 0.5 sec
Safari Sheet 2 (External login)
  ↓ Login success
Form appears ← STILL HERE
  ↓ Can tap "Save" again
Safari Sheet 1 again... ← LOOP
```

## Temporary Workaround

If the loop persists, try using **API Token** method instead:

1. Get tokens manually from Home Assistant:
    - Profile → Security → Long-Lived Access Tokens
    - Create token for internal
    - Create token for external (if URLs point to different systems)
2. Use "API Token" auth type
3. Paste tokens manually
4. This should work without the loop

Once you provide the console output, I can pinpoint the exact issue and fix it!
