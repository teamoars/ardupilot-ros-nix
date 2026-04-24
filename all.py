from dataclasses import dataclass
import sys
import time
from datetime import datetime

import msg

# uhhhh
from cv_bridge import CvBridge

import zenoh
from zenoh.ext import z_serialize
import numpy as np
import cv2
from cyclonedds.idl import IdlStruct
from cyclonedds.idl.types import uint8, int32, uint32, array, sequence
import msgspec

# manually built from
# https://github.com/ros2/common_interfaces/blob/rolling/sensor_msgs/msg/Image.msg
# TODO: just use cyclonedds IDL compiler
@dataclass
class Time(IdlStruct, typename="Time"):
    sec: int32
    nanosec: uint32
@dataclass
class Header(IdlStruct, typename="Time"):
    stamp: Time
    frame_id: str
@dataclass
class Image(IdlStruct, typename='Image'):
    header: Header
    height: uint32
    width: uint32
    encoding: str
    is_bigendian: uint8
    step: uint32
    data: sequence[uint8]

if __name__ == "__main__":
    # for performance reasons (laziness), this is hardcoded for now.
    # Proper solution would have use get P out of the corresponding
    # camera_info topic
    P = [[205.46962738037109, 0.0, 320.0, 0.0], [0.0, 205.46965599060059, 240.0, 0.0], [0.0, 0.0, 1.0, 0.0]]
    P = z_serialize(P)
    br = CvBridge()

    with zenoh.open(zenoh.Config()) as session:
        pub_img = session.declare_publisher('cams/1/img')
        pub_P = session.declare_publisher('cams/1/P')

        with session.declare_subscriber('camera/image') as sub:
            for sample in sub:
                # important that we get the time stamp ASAP
                timestamp = datetime.now()
                a = time.time()
                img_msg = Image.deserialize(sample.payload.to_bytes())
                img = br.imgmsg_to_cv2(img_msg, desired_encoding='bgr8')
                b = time.time()
                print(f'decode took {(b-a) * pow(10, 3)}ms')

                a = time.time()
                ret, jpeg = cv2.imencode('.jpg', img)
                if not ret:
                    print('failed to encode jpg')
                    break
                b = time.time()
                print(f'jpeg took {(b-a) * pow(10, 3)}ms')
                
                a = time.time()
                # pub_img.put(z_serialize((timestamp, jpeg.tobytes())))
                image = msg.Image(timestamp=timestamp, jpeg=jpeg.tobytes())
                msg.encode(image)
                pub_img.put(msg.encode(image))
                pub_P.put(P)
                b = time.time()
                print(f'put took {(b-a) * pow(10, 3)}ms')
