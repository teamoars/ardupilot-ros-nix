# /// script
# requires-python = ">=3.13"
# dependencies = [
#     "numpy",
# ]
# ///

from pprint import pprint

import numpy as np

# https://math.stackexchange.com/questions/2237994/back-projecting-pixel-to-3d-rays-in-world-coordinates-using-pseudoinverse-method


def convert_nx2_to_homo_3xn(points_nx2: np.array):
    return np.hstack([points_nx2, np.ones((points_nx2.shape[0], 1))]).T


def convert_nx3_to_homo_4xn(points_nx3: np.array):
    return np.hstack([points_nx3, np.ones((points_nx3.shape[0], 1))]).T


def cast_2d_points_as_3d_rays(sub_pixels_nx2: np.array, proj_3x4: np.array):
    """
    see Harley & Zisserman pg 162, section 6.2.2, figure 6.14
    see https://math.stackexchange.com/a/597489/541203

    cast rays from camera center through the sub_pixels_nx2. Return camera center and ray directions.
    """
    m_3x3 = proj_3x4[:, :3]
    p4_3x1 = proj_3x4[:, 3]
    m_inv_3x3 = np.linalg.inv(m_3x3)

    # projection matrix to camera center
    camera_center_3x1 = np.expand_dims(-m_inv_3x3 @ p4_3x1, 1)
    camera_center_homo_4x1 = np.vstack([camera_center_3x1, 1])

    # projection matrix + pixel locations to ray directions
    sub_pixels_homo_3xn = convert_nx2_to_homo_3xn(sub_pixels_nx2)
    ray_directions_3xn = m_inv_3x3 @ sub_pixels_homo_3xn
    ray_directions_homo_4xn = convert_nx3_to_homo_4xn(ray_directions_3xn.T)
    ray_directions_homo_4xn[3, :] = 0  # this is a direction

    return ray_directions_homo_4xn, camera_center_homo_4x1

sub_pixels_nx2 = np.array([[320//2, 240//2]])
proj_3x4 = np.array([[277.19135284423828, 0, 160, 0], [0, 277.19135284423828, 120, 0], [0, 0, 1, 0]])
pprint(cast_2d_points_as_3d_rays(sub_pixels_nx2, proj_3x4))
