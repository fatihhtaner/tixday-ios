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

## Episode 2: "How to count down to a birthday every year"
| File | Content |
|---|---|
| `episode-2.mp4` | 1080×1920, 21 s, English voiceover |
| `episode-2-silent.mp4` | Same without voice |

Hook → 1 New ticket → Birthday → 2 Name + birthday date ("Repeats every year" turns on by itself) → 3 Save it → ★ Bonus: it rolls over to next year (details show "Every year") → closing card.

**Caption (copy):** Never forget a birthday again 🎂 Set it once, it counts down every year. #birthday #countdown #iphonewidgets #iphonetips #tixday

## Re-make / new episode
1. `xcrun simctl create "Tixday Video" "iPhone 17 Pro Max"` (once), Debug build in `build/`.
2. `tools/capture_tutorial_clips.sh en en_US build/tutorial/en` (clips: `create`, `widgets`, `birthday`; the app plays each flow itself via `-screenshotScreen create-demo` / `birthday-demo`).
3. `swift tools/make_tutorial_video.swift docs/marketing/tutorial/episode-1.json build/tutorial/en docs/marketing/tutorial/episode-1.mp4 [--silent]`

## Next episodes (ideas)
- How to put a countdown on your Lock Screen
- How to use your own photo on a countdown widget
- How many days until Christmas? (seasonal)

Note: within one clip, start each scene where the previous one ended; a gap between them makes AVFoundation fail to compose.
