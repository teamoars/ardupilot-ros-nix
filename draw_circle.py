#!/usr/bin/python3
import time
import math

import cv2
from cv_bridge import CvBridge
from ultralytics import YOLO

import rclpy
from rclpy.qos import QoSProfile
from rclpy.qos import QoSHistoryPolicy
from rclpy.qos import QoSDurabilityPolicy
from rclpy.qos import QoSReliabilityPolicy
from rclpy.executors import ExternalShutdownException
from rclpy.node import Node
from sensor_msgs.msg import Image
from geometry_msgs.msg import TwistStamped
# from ardupilot_msgs.msg import Arm
from ardupilot_msgs.srv import ArmMotors
from builtin_interfaces.msg import Time

class HoverNode(Node):
    def __init__(self):
        super().__init__('hover')

        self.get_logger().info("starting")

        self.cmd_vel_pub_ = self.create_publisher(TwistStamped, '/ap/cmd_vel', 10)
        self.timer_ = self.create_timer(0.5, self.send_velocity_command)
        self.cv_bridge = CvBridge()
        # self.yolo = YOLO('yolov8n.pt')
        self.yolo = YOLO('yolov8n_openvino_model/')

        # subscribe to camera images
        self.image_qos_profile = QoSProfile(
            reliability=QoSReliabilityPolicy.BEST_EFFORT,
            history=QoSHistoryPolicy.KEEP_LAST,
            durability=QoSDurabilityPolicy.VOLATILE,
            depth=1,
        )
        # TODO: what is a 10 qos profile?
        self._sub = self.create_subscription(
            # Image, "image_raw", self.image_cb, self.image_qos_profile
            # Image, "/camera/image", self.image_cb, self.image_qos_profile
            Image, "/camera/image", self.image_cb, 10
        )
        self._pub = self.create_publisher(Image, '/yolo/image', 10)

        self.get_logger().info("Draw circle node has been started")

    def image_cb(self, msg):
        self.get_logger().info('handling image')

        cv_image = self.cv_bridge.imgmsg_to_cv2(
            msg, desired_encoding='passthrough'
        )
        results = self.yolo.predict(
            source=cv_image,
            verbose=False,
            stream=False,
            # conf=self.threshold,
            # iou=self.iou,
            # imgsz=(self.imgsz_height, self.imgsz_width),
            # imgsz=(480, 640),
            # half=self.half,
            # max_det=self.max_det,
            # augment=self.augment,
            # agnostic_nms=self.agnostic_nms,
            # retina_masks=self.retina_masks,
            device='cpu',
        )

        # render the results
        for r in results:
            boxes = r.boxes

            for box in boxes:
                # bounding box
                x1, y1, x2, y2 = box.xyxy[0]
                x1, y1, x2, y2 = int(x1), int(y1), int(x2), int(y2) # convert to int values

                # put box in cam
                cv2.rectangle(cv_image, (x1, y1), (x2, y2), (255, 0, 255), 3)

                # confidence
                confidence = math.ceil((box.conf[0]*100))/100
                print("Confidence --->",confidence)

                # class name
                cls = int(box.cls[0])
                # print("Class name -->", classNames[cls])

                # object details
                org = [x1, y1]
                font = cv2.FONT_HERSHEY_SIMPLEX
                fontScale = 1
                color = (255, 0, 0)
                thickness = 2

                cv2.putText(cv_image, self.yolo.names[cls], org, font, fontScale, color, thickness)
        # draw the result
        image = self.cv_bridge.cv2_to_imgmsg(cv_image, encoding='passthrough')
        self._pub.publish(image)

        self.get_logger().info('done with frame')

    def send_velocity_command(self):
        one = Time()
        one.nanosec = 100000

        msg_fwd = TwistStamped()
        msg_fwd.header.stamp = one
        msg_fwd.header.frame_id = 'map'
        # msg_fwd.twist.linear.x = 2.0
        # msg_fwd.twist.angular.z = 0.2
        # msg_fwd.twist.angular.z = 5.0

        msg_fwd.twist.linear.y = 5.0

        self.get_logger().info("publishing velocity command")
        self.cmd_vel_pub_.publish(msg_fwd)

class MinimalClientAsync(Node):

    def __init__(self):
        super().__init__('minimal_client_async')
        self.cli = self.create_client(ArmMotors, '/ap/arm_motors')
        while not self.cli.wait_for_service(timeout_sec=1.0):
            self.get_logger().info('service not available, waiting again...')
        self.req = ArmMotors.Request()

    def send_arm_request(self):
        self.req.arm = True
        return self.cli.call_async(self.req)


def main(args=None):
    # TODO: why doesn't context manager work?
    try:
        rclpy.init(args=args)

        minimal_client = MinimalClientAsync()
        future = minimal_client.send_arm_request()
        rclpy.spin_until_future_complete(minimal_client, future)
        armed = future.result().result
        if armed:
            minimal_client.get_logger().info('we are armed')
        else:
            minimal_client.get_logger().info('arming failed')
            exit()

        hover = HoverNode()
        rclpy.spin(hover)

        rclpy.shutdown()
    except (KeyboardInterrupt, ExternalShutdownException):
        pass

# def main(args=None):
#     rclpy.init(args=args)
# 
#     self.get_logger().debug('sending arm request')
#     ArmMotors.Request(arm=True)
# 
#     node = DrawCircleNode()
#     rclpy.spin(node)
# 
#     rclpy.shutdown()

if __name__ == '__main__':
        main()
