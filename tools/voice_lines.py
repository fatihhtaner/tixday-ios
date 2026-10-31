#!/usr/bin/env python3
"""Reads a video spec's spoken lines with a local VoxCPM2 voice and writes one trimmed, sped-up clip per line.

The clips (line0.wav, line1.wav, …, in the same order as make_tutorial_video.swift speaks them: scene lines,
then the closing line) are picked up with `--voices <dir>`; the video stretches a scene when its line runs long.

Usage:
  python3 tools/voice_lines.py <spec.json> <out-dir> --ses sakin_en/2 --speed 1.12
Copied from Subloom (same voice as its videos); Tixday's specs are English, so the language defaults to en.

Needs the VoxCPM2 checkout at ~/voxcpm2-turkce-ses-tasarimi (or VOXCPM_DIR) and the compiled
tools/speed_audio.swift (SPEED_BIN, default: compiled on first use into build/speed_audio).
"""
import argparse
import hashlib
import json
import os
import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
VOX = Path(os.environ.get("VOXCPM_DIR", Path.home() / "voxcpm2-turkce-ses-tasarimi"))
# Runs inside the VoxCPM2 venv (numpy + soundfile): slices the reading into lines, trims the silence around
# each line and shortens long pauses inside it (the engine sometimes stops for half a second mid-sentence).
SLICER = r"""
import json, sys
import numpy as np, soundfile as sf
summary, out = json.load(open(sys.argv[1])), sys.argv[2]
audio, rate = sf.read(summary["wav"], dtype="float32")
mono = audio if audio.ndim == 1 else audio.mean(axis=1)
for n, line in enumerate(summary["satirlar"]):
    a, b = int(line["t0"] * rate), int(line["t1"] * rate)
    part = mono[a:b]
    loud = np.flatnonzero(np.abs(part) > 0.02)
    if len(loud):
        pad = int(0.06 * rate)
        part = part[max(0, loud[0] - pad):min(len(part), loud[-1] + pad)]
    # 20 ms windows; a quiet run longer than 0.3 s is cut down to 0.2 s.
    window = int(0.02 * rate)
    quiet = [np.abs(part[i:i + window]).max() < 0.02 for i in range(0, len(part), window)]
    keep, run = [], 0
    for i, still in enumerate(quiet):
        run = run + 1 if still else 0
        if run <= 10 or not still:
            keep.append(part[i * window:(i + 1) * window])
    part = np.concatenate(keep) if keep else part
    sf.write(f"{out}/raw{n}.wav", part, rate)
"""
# Levels the finished lines (after the speed-up, which pushes peaks around) to the same loudness: -17 dB RMS over
# the voiced parts, so one line doesn't sound quieter than the next; a soft limiter keeps peaks under -2 dBFS for AAC.
NORMALIZER = r"""
import sys
import numpy as np, soundfile as sf
for path in sys.argv[1:]:
    audio, rate = sf.read(path, dtype="float32")
    voiced = audio[np.abs(audio) > 0.02]
    rms = np.sqrt((voiced ** 2).mean()) if len(voiced) else 1.0
    audio = audio * (10 ** (-17 / 20) / rms)
    # Soft limiter: above 0.55 the peaks bend smoothly towards 0.8 instead of clipping.
    loud = np.abs(audio) > 0.55
    audio[loud] = np.sign(audio[loud]) * (0.55 + 0.25 * np.tanh((np.abs(audio[loud]) - 0.55) / 0.25))
    sf.write(path, audio, rate, subtype="PCM_16")
"""


def spoken_lines(spec):
    lines = [scene["voice"] for scene in spec["scenes"] if scene.get("voice")]
    if spec["closing"].get("voice"):
        lines.append(spec["closing"]["voice"])
    return lines


def vox_text(line, language):
    """What the engine reads: no apostrophes or quotes (Subloom'da -> Subloomda), digits are rejected."""
    text = re.sub(r"[\"“”«»]", "", line)
    if language == "tr":
        text = re.sub(r"[’']", "", text)
    if re.search(r"\d", text):
        sys.exit(f"spell out the digits for the voice: {line}")
    return text


def speed_bin():
    path = Path(os.environ.get("SPEED_BIN", ROOT / "build/speed_audio"))
    if not path.exists():
        path.parent.mkdir(parents=True, exist_ok=True)
        subprocess.run(["swiftc", "-O", str(ROOT / "tools/speed_audio.swift"), "-o", str(path)], check=True)
    return path


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("spec")
    parser.add_argument("out")
    parser.add_argument("--ses", required=True, help="VoxCPM2 voice: hazir/<name> or <name>/<variant>")
    parser.add_argument("--dil", default="en", help="text language: tr or en (default: en)")
    parser.add_argument("--speed", type=float, default=1.0)
    args = parser.parse_args()

    spec = json.loads(Path(args.spec).read_text())
    language = args.dil
    lines = [vox_text(line, language) for line in spoken_lines(spec)]
    out = Path(args.out).resolve()
    out.mkdir(parents=True, exist_ok=True)

    # The reading is slow (minutes): reuse it when the text and voice are unchanged.
    key = hashlib.sha1(json.dumps([lines, args.ses, language]).encode()).hexdigest()
    stamp = out / "key.txt"
    reading = out / "okuma"
    summary = reading / "ozet.json"
    python = VOX / ".venv/bin/python"
    if not (stamp.exists() and stamp.read_text() == key and summary.exists()):
        (out / "metin.txt").write_text("\n".join(lines) + "\n")
        command = [str(python), "-m", "ses_tasarim.oku", "--ses", args.ses, "--metin", f"@{out / 'metin.txt'}",
                   "--cikti", str(reading), "--dil", language]
        subprocess.run(command, cwd=VOX, check=True)
        stamp.write_text(key)
    # The engine sometimes cuts a sentence to a fraction of a second (the same text always reads the same way,
    # so rerunning doesn't help): stop and say which lines to reword.
    cut = [line["metin"] for line in json.loads(summary.read_text())["satirlar"]
           if line["t1"] - line["t0"] < 0.18 * len(line["metin"].split()) + 0.3]
    if cut:
        stamp.unlink()
        sys.exit("the engine cut these lines short, reword them slightly:\n  " + "\n  ".join(cut))
    if len(json.loads(summary.read_text())["satirlar"]) != len(lines):
        sys.exit("the engine read a different number of lines")
    subprocess.run([str(python), "-I", "-c", SLICER, str(summary), str(out)], check=True)
    speed = speed_bin()
    for n in range(len(lines)):
        subprocess.run([str(speed), str(out / f"raw{n}.wav"), str(out / f"fast{n}.wav"), str(args.speed)],
                       check=True, stdout=subprocess.DEVNULL)
        # Same format as the video's silence track (44.1 kHz stereo), or the export keeps the voice as a
        # second audio track that most players never play.
        subprocess.run(["afconvert", "-f", "WAVE", "-d", "LEI16@44100", "-c", "2",
                        str(out / f"fast{n}.wav"), str(out / f"line{n}.wav")], check=True)
    subprocess.run([str(python), "-I", "-c", NORMALIZER, *[str(out / f"line{n}.wav") for n in range(len(lines))]],
                   check=True)
    print(f"wrote {len(lines)} lines to {out}")


if __name__ == "__main__":
    main()
