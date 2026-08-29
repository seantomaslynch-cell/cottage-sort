#!/usr/bin/env python3
"""Summarise the local analytics log so the M15 difficulty curve can be tuned.

The game writes JSON lines to `user://events.log` via game/analytics.gd. On
Windows that resolves to:
    %APPDATA%/Godot/app_userdata/Cottage Sort/events.log

Usage:
    python tools/analyze_events.py [path/to/events.log]
"""
import json
import os
import sys
from collections import defaultdict


def default_path():
    appdata = os.environ.get("APPDATA", "")
    return os.path.join(appdata, "Godot", "app_userdata", "Cottage Sort", "events.log")


def load(path):
    rows = []
    with open(path, "r", encoding="utf-8") as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            try:
                rows.append(json.loads(line))
            except json.JSONDecodeError:
                pass
    return rows


def main():
    path = sys.argv[1] if len(sys.argv) > 1 else default_path()
    if not os.path.exists(path):
        print(f"no log at {path}\nplay the game (a debug build) to generate one.")
        return

    rows = load(path)
    by_event = defaultdict(int)
    for r in rows:
        by_event[r.get("e", "?")] += 1

    sessions = by_event.get("session_start", 0)
    print(f"log: {path}")
    print(f"{len(rows)} events across {sessions} sessions\n")

    # --- level funnel -----------------------------------------------------
    starts = defaultdict(int)
    completes = defaultdict(int)
    fails = defaultdict(int)
    moves_sum = defaultdict(int)
    stars_sum = defaultdict(int)
    last_started = None

    quits = defaultdict(int)  # stage started but the run never completed/failed after it
    for r in rows:
        e = r.get("e")
        s = r.get("stage")
        if e == "level_start":
            if last_started is not None:
                quits[last_started] += 1
            last_started = s
            starts[s] += 1
        elif e == "level_complete":
            completes[s] += 1
            moves_sum[s] += int(r.get("moves", 0))
            stars_sum[s] += int(r.get("stars", 0))
            last_started = None
        elif e == "level_fail":
            fails[s] += 1

    print("stage | starts | done | fail | done% | avg moves | avg stars | quit-after")
    for s in sorted(k for k in starts if k is not None):
        d, st, fl = completes[s], starts[s], fails[s]
        rate = (d / st * 100) if st else 0
        am = (moves_sum[s] / d) if d else 0
        as_ = (stars_sum[s] / d) if d else 0
        print(f"{s:>5} | {st:>6} | {d:>4} | {fl:>4} | {rate:>4.0f}% | "
              f"{am:>9.1f} | {as_:>9.2f} | {quits[s]:>10}")

    # rough churn point
    if quits:
        worst = max(quits, key=quits.get)
        print(f"\nmost common quit-after stage: L{worst + 1} ({quits[worst]} sessions)")

    # --- monetization / ads --------------------------------------------
    print()
    print(f"rewarded ads watched : {by_event.get('ad_reward', 0)}")
    print(f"interstitials shown  : {by_event.get('interstitial', 0)}  "
          f"(note: analytics.gd doesn't log these yet)")
    print(f"boosters used        : {by_event.get('booster_used', 0)}")
    iaps = defaultdict(int)
    for r in rows:
        if r.get("e") == "iap":
            iaps[r.get("id", "?")] += 1
    if iaps:
        print("iap purchases:")
        for k, v in sorted(iaps.items(), key=lambda kv: -kv[1]):
            print(f"  {k:<16} {v}")

    print("\nall event types:")
    for k, v in sorted(by_event.items(), key=lambda kv: -kv[1]):
        print(f"  {k:<20} {v}")


if __name__ == "__main__":
    main()
