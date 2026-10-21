# Tutorial videos (TikTok / Reels / Shorts, English)

One "how to" question per video, solved in 3 numbered steps; Tixday is the natural part of the answer.

## Episode 1: "How to put a countdown on your iPhone Home Screen"
| File | Content |
|---|---|
| `episode-1.mp4` | 1080×1920, 19 s, English voiceover (macOS "Samantha") |
| `episode-1-silent.mp4` | Same without voice: add your own voice or TikTok's text-to-speech |

Hook → 1 Tap New ticket → 2 Name it, pick the date → 3 Save it → ★ Bonus: add the widget → closing card.
Voice lines are the `voice` fields in `episode-1.json`.

**Caption (copy):** How to put a countdown on your iPhone Home Screen ✈️ Every date becomes a ticket. #countdown #iphonewidgets #homescreen #iphonetips #travel #tixday
Turn on TikTok's auto captions (the guide: sound + captions doubles reach).

## Re-make / new episode
1. `xcrun simctl create "Tixday Video" "iPhone 17 Pro Max"` (once), Debug build in `build/`.
2. `tools/capture_tutorial_clips.sh en en_US build/tutorial/en` (clips: `create`, `widgets`; the app plays the flow itself via `-screenshotScreen create-demo`).
3. `swift tools/make_tutorial_video.swift docs/marketing/tutorial/episode-1.json build/tutorial/en docs/marketing/tutorial/episode-1.mp4 [--silent]`

## Next episodes (ideas)
- How to count down to a birthday every year (yearly tickets)
- How to put a countdown on your Lock Screen
- How to use your own photo on a countdown widget
- How many days until Christmas? (seasonal)
