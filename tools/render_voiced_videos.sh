#!/bin/bash
# Renders the tutorial videos (and the episode 2 hook variants) with the VoxCPM2 voice used for Subloom's
# videos: voiced + silent. Readings are cached per video in build/voices, so a rerun after a text change
# only re-reads that video. Needs the clips in build/tutorial/en (tools/capture_tutorial_clips.sh).
#
# Usage: tools/render_voiced_videos.sh [spec.json …]   (run from the repo root; default: every episode and hook)
set -euo pipefail
VOICE="${VOICE:-sakin_en/2}"; SPEED="${SPEED:-1.12}"
specs=("$@")
[[ ${#specs[@]} -gt 0 ]] || specs=(docs/marketing/tutorial/episode-*.json docs/marketing/tutorial/hooks/*.json)
for spec in "${specs[@]}"; do
  name=$(basename "$spec" .json)
  out="${spec%.json}"
  voices="build/voices/$name"
  echo "== $name"
  python3 tools/voice_lines.py "$spec" "$voices" --ses "$VOICE" --speed "$SPEED"
  swift tools/make_tutorial_video.swift "$spec" build/tutorial/en "$out.mp4" --voices "$voices"
  swift tools/make_tutorial_video.swift "$spec" build/tutorial/en "$out-silent.mp4" --voices "$voices" --silent
done
