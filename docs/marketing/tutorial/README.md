# Tutorial videos (TikTok / Reels / Shorts, English)

One "how to" question per video, solved in 3 numbered steps; Tixday is the natural part of the answer.

## Episode 1: "How to put a countdown on your iPhone Home Screen"
| File | Content |
|---|---|
| `episode-1.mp4` | 1080×1920, 19 s, English voiceover (VoxCPM2 `sakin_en/2`, the voice of Subloom's videos) |
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

## Episode 3: "How many days until Christmas?"
| File | Content |
|---|---|
| `episode-3.mp4` | 1080×1920, 21 s, English voiceover |
| `episode-3-silent.mp4` | Same without voice |

Hook → 1 New ticket → Holiday → 2 Name it, pick December 25 ("Repeats every year" turns on by itself) → 3 Save it → ★ Bonus: add the widget → closing card. Post by mid-November.

**Caption (copy):** How many days until Christmas? 🎄 Put the answer on your Home Screen. #christmas #countdown #iphonewidgets #iphonetips #tixday

## Re-make / new episode
1. `xcrun simctl create "Tixday Video" "iPhone 17 Pro Max"` (once), Debug build in `build/`.
2. `tools/capture_tutorial_clips.sh en en_US build/tutorial/en` (clips: `create`, `widgets`, `birthday`, `christmas`, `christmas-widgets`; the app plays each flow itself via `-screenshotScreen create-demo` / `birthday-demo` / `christmas-demo`).
3. `tools/render_voiced_videos.sh [spec.json …]`: reads the lines with the local VoxCPM2 voice (`~/voxcpm2-turkce-ses-tasarimi`, `sakin_en/2` ×1.12; `VOICE`/`SPEED` change it) and renders the voiced + silent video. Spell out digits in `voice` lines ("twenty-fifth").
   Without VoxCPM2: `swift tools/make_tutorial_video.swift <spec.json> build/tutorial/en <out.mp4> [--silent]` uses macOS `say`.

## Next episodes (ideas)
- How to put a countdown on your Lock Screen
- How to use your own photo on a countdown widget

Note: within one clip, start each scene where the previous one ended; a gap between them makes AVFoundation fail to compose.
