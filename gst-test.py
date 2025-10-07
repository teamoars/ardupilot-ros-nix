# /// script
# requires-python = ">=3.13"
# dependencies = [
#     "opencv-python",
# ]
# ///

import cv2

# gst_cmd = "gst-launch-1.0 -v udpsrc port=5601 caps='application/x-rtp, media=(string)video, clock-rate=(int)90000, encoding-name=(string)H264' ! rtph264depay ! avdec_h264 ! videoconvert ! autovideosink sync=false"
gst_cmd = "udpsrc port=5601 caps='application/x-rtp, media=(string)video, clock-rate=(int)90000, encoding-name=(string)H264' ! rtph264depay ! avdec_h264 ! '! decodebin ! videoconvert ! video/x-raw,format=(string)BGR ! videoconvert' ! appsink sync=false"

print('creating video capture')
cap = cv2.VideoCapture(gst_cmd, cv2.CAP_GSTREAMER)
# cap = cv2.VideoCapture('rtp://localhost:5601')

print('checking if opened')
if cap.isOpened() is not True:
    print("Cannot open camera. Exiting.")
    quit()

print('going into loop')
while True:
    print('going to read')
    ret, frame = cap.read()

    print('imshowing')
    cap.imshow('webcam',frame)

    if cv2.waitKey(1)==ord('q'):
        break

cap.release()
cv2.destroyAllWindows()
