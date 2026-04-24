from datetime import datetime

import msgspec

class Image(msgspec.Struct):
    timestamp: datetime
    jpeg: bytes

class XYXY(msgspec.Struct):
    timestamp: datetime
    xyxy: list[list[float]]

class Yaw(msgspec.Struct):
    timestamp: datetime
    yaw: list[float]

type Msg = Image | XYXY | Yaw

_encoder = msgspec.msgpack.Encoder()
def encode(msg: Msg) -> bytes:
    return _encoder.encode(msg)

def decode_image(image: bytes) -> Image:
    return msgspec.msgpack.decode(image, type=Image)
def decode_xyxy(xyxy: bytes) -> XYXY:
    return msgspec.msgpack.decode(xyxy, type=XYXY)
def decode_yaw(detection: bytes) -> Yaw:
    return msgspec.msgpack.decode(detection, type=Yaw)
