# /// script
# requires-python = ">=3.13"
# dependencies = [
#     "numpy",
# ]
# ///

import numpy as np

# taken from the gazebo topic "/camera_info":
# projection {
#   p: 277.19135284423828
#   p: 0
#   p: 160
#   p: 0
#   p: 0
#   p: 277.19135284423828
#   p: 120
#   p: 0
#   p: 0
#   p: 0
#   p: 1
#   p: 0
# }
P = np.array([[277.19135284423828, 0, 160, 0], [0, 277.19135284423828, 120, 0], [0, 0, 1, 0]])
print(P)

m_3x3 = P[:, :3]
p4_3x1 = P[:, 3]
m_inv_3x3 = np.linalg.inv(m_3x3)

# projection matrix to camera center
camera_center_3x1 = np.expand_dims(-m_inv_3x3 @ p4_3x1, 1)
camera_center_homo_4x1 = np.vstack([camera_center_3x1, 1])

print(camera_center_homo_4x1)
