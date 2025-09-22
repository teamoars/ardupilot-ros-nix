#!/usr/bin/env python3
import rclpy
import math
import time

from rclpy.node import Node
from geometry_msgs.msg import TwistStamped
from ardupilot_msgs.msg import GlobalPosition
from geopy import distance
from geopy import point
from ardupilot_msgs.srv import ArmMotors
from ardupilot_msgs.srv import ModeSwitch
from geographic_msgs.msg import GeoPointStamped

COPTER_MODE_TAKEOFF = 0
COPTER_MODE_GUIDED = 4
MAV_FRAME_LOCAL_NED = 1

class SinusoidalCommandPublisher(Node):
    def __init__(self):
        super().__init__("sinusoidal_cmd_publisher")

        self.declare_parameter("arm_topic", "/ap/arm_motors")
        self._arm_topic = self.get_parameter("arm_topic").get_parameter_value().string_value
        self._client_arm = self.create_client(ArmMotors, self._arm_topic)
        while not self._client_arm.wait_for_service(timeout_sec=1.0):
            self.get_logger().info('arm service not available, waiting again...')
        
        self.declare_parameter("mode_topic", "/ap/mode_switch")
        self._mode_topic = self.get_parameter("mode_topic").get_parameter_value().string_value
        self._client_mode_switch = self.create_client(ModeSwitch, self._mode_topic)
        while not self._client_mode_switch.wait_for_service(timeout_sec=1.0):
            self.get_logger().info('mode switch service not available, waiting again...')
            
        # Velocity Publisher
        # self.declare_parameter("cmd_vel_topic", "/ap/cmd_vel")
        # self._cmd_vel_topic =  self.get_parameter("cmd_vel_topic").get_parameter_value().string_value 
        # self._cmd_vel_pub = self.create_publisher(TwistStamped, self._cmd_vel_topic, 11)
        
        # Positinom Publisher
        self.declare_parameter("global_position_topic", "/ap/cmd_gps_pose")
        self._global_pos_topic = self.get_parameter("global_position_topic").get_parameter_value().string_value
        self._global_pos_pub = self.create_publisher(GlobalPosition, self._global_pos_topic, 1)

        # Start timer loop
        self.timer_period = 0.1  # 10 Hz
        self.timer = self.create_timer(self.timer_period, self.timer_callback)
        self.start_time = self.get_clock().now().nanoseconds / 1e9

        # Define motion parameters
        self.amp = 1/1000000       # amplitude in degrees (≈11m)
        self.freq = 10         # Hz (slow)
        self.base_lat = -35.3627010
        self.base_lon = 149.1651513
        self.altitude = 630.0     # meters MSL
    
    def timer_callback(self):
        # Compute elapsed time
        t = self.get_clock().now().nanoseconds / 1e9 - self.start_time

        # Sinusoidal longitude offset
        offset = self.amp * math.sin(2 * math.pi * self.freq * t)
        offset_dot = self.amp * 2 * math.pi * self.freq * math.cos(2 * math.pi * self.freq * t)

        # ======= Publish Position (GlobalPosition) =======
        pos_msg = GlobalPosition()
        pos_msg.header.stamp = self.get_clock().now().to_msg()
        pos_msg.header.frame_id = "map"
        pos_msg.latitude = self.base_lat
        pos_msg.longitude = self.base_lon + offset
        pos_msg.altitude = self.altitude
        pos_msg.coordinate_frame = MAV_FRAME_LOCAL_NED  

        self._global_pos_pub.publish(pos_msg)

        # ======= Publish Velocity (TwistStamped) =======
        # vel_msg = TwistStamped()
        # vel_msg.header.stamp = self.get_clock().now().to_msg()
        # vel_msg.twist.linear.x = 0.0  # no N-S velocity
        # vel_msg.twist.linear.y = offset_dot * 111139.0  # convert deg/s to m/s (lon scale at equator)
        # vel_msg.twist.linear.z = 0.0

        # self._cmd_vel_pub.publish(vel_msg)

    def arm(self):
        req = ArmMotors.Request()
        req.arm = True
        future = self._client_arm.call_async(req)
        rclpy.spin_until_future_complete(self, future)
        return future.result()

    def arm_with_timeout(self, timeout: rclpy.duration.Duration):
        """Try to arm. Returns true on success, or false if arming fails or times out."""
        armed = False
        start = self.get_clock().now()
        while not armed and self.get_clock().now() - start < timeout:
            armed = self.arm().result
            time.sleep(1)
        print(f"armed succesfull")
        return armed

    def switch_mode(self, mode):
        req = ModeSwitch.Request()
        assert mode in [COPTER_MODE_TAKEOFF, COPTER_MODE_GUIDED]
        req.mode = mode
        future = self._client_mode_switch.call_async(req)
        rclpy.spin_until_future_complete(self, future)
        return future.result()

    def switch_mode_with_timeout(self, desired_mode: int, timeout: rclpy.duration.Duration):
        """Try to switch mode. Returns true on success, or false if mode switch fails or times out."""
        print(f"attempting to switch to mode {desired_mode}....")
        is_in_desired_mode = False
        start = self.get_clock().now()
        while not is_in_desired_mode:
            result = self.switch_mode(desired_mode)
            # Handle successful switch or the case that the vehicle is already in expected mode
            is_in_desired_mode = result.status or result.curr_mode == desired_mode
            time.sleep(1)

        return is_in_desired_mode
    
def main(args=None):
    rclpy.init(args=args)
    node = SinusoidalCommandPublisher()
    try:
        # Block till armed, which will wait for EKF3 to initialize
        if not node.arm_with_timeout(rclpy.duration.Duration(seconds=30)):
            raise RuntimeError("Unable to arm")

        # Block till in guided mode
        if not node.switch_mode_with_timeout(COPTER_MODE_GUIDED, rclpy.duration.Duration(seconds=40)):
            raise RuntimeError("Unable to switch to guided mode")
        
        # Block till in takeoff mode
        if not node.switch_mode_with_timeout(COPTER_MODE_TAKEOFF, rclpy.duration.Duration(seconds=40)):
            raise RuntimeError("Unable to switch to takeoff mode")
        
        startTime = node.get_clock().now()
        while True:
            rclpy.spin_once(node)
            time.sleep(1.0)
            
    except KeyboardInterrupt:
        pass
    node.destroy_node()
    rclpy.shutdown()

if __name__ == "__main__":
    main()
