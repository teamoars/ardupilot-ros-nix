#!/usr/bin/env -S uv run --script
#
# /// script
# requires-python = ">=3.13"
# dependencies = [
#     "numpy",
#     "opencv-python",
#     "pytransform3d[all]",
# ]
# ///

import os

import cv2
import numpy as np

# all of the cameras currently have a common P
P = np.array([[277.19135284423828, 0, 160, 0], [0, 277.19135284423828, 120, 0], [0, 0, 1, 0]])
cameras = [
    # position, pose, P
    (
        (40, 0, 1.0),
        (0, 0, 3.14),
        P
    ),
    (
        (0, 40, 1.0),
        (0, 0, -1.57),
        P
    ),
    (
        (-40, 0, 1.0),
        (0, 0, 0),
        P
    ),
]

# TODO: is this really the best way?
os.environ["OPENCV_FFMPEG_CAPTURE_OPTIONS"] = "protocol_whitelist;file,rtp,udp"
caps = [cv2.VideoCapture(f'camera-{cam}.sdp') for cam in range(1,3+1)]

if any(not cap.isOpened() for cap in caps):
    print('Cannot open a stream')
    exit(1)

cv2.namedWindow('frames', cv2.WINDOW_KEEPRATIO)
cv2.resizeWindow('frames', 1000, 1000)
# TODO: does it matter if we ignore ret?
prev_frames = [cap.read()[1] for cap in caps]

while True:
    # TODO: does it matter if we ignore ret?
    frames = [cap.read()[1] for cap in caps]

    # TODO: stupid
    diffs = [cv2.absdiff(prev, curr) for prev, curr in zip(prev_frames, frames)]
    threshs = [cv2.threshold(diff, 0, 255, cv2.THRESH_BINARY)[1] for diff
               in diffs]

    frame = cv2.vconcat(frames)
    # diff = cv2.vconcat(diffs)
    thresh = cv2.vconcat(threshs)
    # cv2.imshow('frames', cv2.hconcat([frame, diff, thresh]))
    cv2.imshow('frames', cv2.hconcat([frame, thresh]))
    if cv2.waitKey(1) & 0xFF == ord('q'):
        break

    frames_prev = frames

for cap in caps:
    cap.release()
cv2.destroyAllWindows()
