#!/usr/bin/env -S uv run --script
#
# /// script
# requires-python = ">=3.12"
# dependencies = [
#     "numpy",
#     "opencv-python",
#     "pytransform3d>=3.14.3",
# ]
# ///

import os

import matplotlib.animation as animation
import matplotlib.pyplot as plt
import numpy as np

from pytransform3d.plot_utils import Frame, Camera, make_3d_axis, plot_vector
from pytransform3d.rotations import matrix_from_euler, active_matrix_from_extrinsic_roll_pitch_yaw
from pytransform3d.transformations import transform_from, invert_transform, transform

# all of the cameras currently have a common P
# TODO: 'cameras' should have dimensions inside them
P = np.array([[277.19135284423828, 0, 160, 0], [0, 277.19135284423828, 120, 0], [0, 0, 1, 0]])
cameras = [
    # rotation, position
    # roll, pitch, yaw
    # color
    (
        np.array([0, 0, 3.14]),
        np.array([40, 0, 1.0]),
        'cyan',
    ),
    (
        np.array([0, 0, -1.57]),
        np.array([0, 40, 1.0]),
        'orange',
    ),
    (
        np.array([0, 0, 0]),
        np.array([-40, 0, 1.0]),
        'green',
    ),
]

# https://math.stackexchange.com/questions/2237994/back-projecting-pixel-to-3d-rays-in-world-coordinates-using-pseudoinverse-method
def convert_nx2_to_homo_3xn(points_nx2: np.array):
    return np.hstack([points_nx2, np.ones((points_nx2.shape[0], 1))]).T
def convert_nx3_to_homo_4xn(points_nx3: np.array):
    return np.hstack([points_nx3, np.ones((points_nx3.shape[0], 1))]).T
def cast_2d_points_as_3d_rays(sub_pixels_nx2: np.array, proj_3x4: np.array):
    """
    see Harley & Zisserman pg 162, section 6.2.2, figure 6.14
    see https://math.stackexchange.com/a/597489/541203

    cast rays from camera center through the sub_pixels_nx2. Return camera ray directions.
    """
    m_3x3 = proj_3x4[:, :3]
    p4_3x1 = proj_3x4[:, 3]
    m_inv_3x3 = np.linalg.inv(m_3x3)

    # projection matrix + pixel locations to ray directions
    sub_pixels_homo_3xn = convert_nx2_to_homo_3xn(sub_pixels_nx2)
    ray_directions_3xn = m_inv_3x3 @ sub_pixels_homo_3xn
    ray_directions_homo_4xn = convert_nx3_to_homo_4xn(ray_directions_3xn.T)
    ray_directions_homo_4xn[3, :] = 0  # this is a direction

    return ray_directions_homo_4xn

if __name__ == "__main__":
    n_frames = 50

    fig = plt.figure(figsize=(5, 5))
    ax = make_3d_axis(40)

    # frame = Frame(np.eye(4), label="target", s=3, draw_label_indicator=False)
    # frame.add_frame(ax)

    for rotation, position, color in cameras:
        # https://github.com/dfki-ric/pytransform3d/discussions/148
        #
        # gazebo focal length according to random guy on stackexchange
        # TODO: is this just derived from the pinhole model or specific to gazebo?
        # https://robotics.stackexchange.com/questions/31142/incorrect-camera-extrinsics-for-simulated-gazebo-cameras
        # 
        # > focal_lengtth = image_width / (2*tan(hfov_radian / 2)
        #
        # https://stackoverflow.com/questions/14038002/opencv-how-to-calculate-distance-between-camera-and-object-using-image
        # https://en.wikipedia.org/wiki/Camera_resectioning
        w, h = 320, 240  # [pixels]
        M = P[:, :3]
        tf = transform_from(
            # gazebo has x up by default but pytransform3d has z up
            matrix_from_euler(
                [-np.pi/2, 0, -np.pi/2] + rotation,
                0, 1, 2,
                True
            ),
            position,
        )

        camera = Camera(
            M,
            tf,
            virtual_image_distance=5,
            sensor_size=(w, h),
            color=color,
        )
        camera.add_camera(ax)
        frame = Frame(tf, label="cam", s=3, draw_label_indicator=False)
        frame.add_frame(ax)

        # just some test points
        point = np.array([
            # corners
            [0, 0],
            [0, 240],
            [320, 0],
            [320, 240],
            # center
            [320//2, 240//2],
        ])
        direction = cast_2d_points_as_3d_rays(point, P)

        # TODO: when doing this for real, just add the extrinsics to P and
        # then we won't need to apply a transform here
        direction_world = transform(tf, direction.T)
        for idx in range(direction_world.shape[0]):
            t = plot_vector(
                start=position,
                # direction=direction[:, 0],
                direction=direction_world[idx, :],
                s=10,
                color='red',
                ax=ax,
            )

    from pprint import pprint
    pprint(t)

    plt.show()
