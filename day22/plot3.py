import matplotlib.pyplot as plt
import numpy as np

#fig = plt.figure()
#ax = fig.add_subplot(projection='3d')

file1 = open("coords.csv", "r")
lines = file1.readlines()

xs = []
ys = []
zs = []
faces = []
for line in lines:
    ll = line.strip()
    parts = line.split(";")
    x = int(parts[0])
    y = int(parts[1])
    z = int(parts[2])
    face = int(parts[3])
    xs.append(x)
    ys.append(y)
    zs.append(z)
    faces.append(face)

xmin = min(xs)
ymin = min(ys)
zmin = min(zs)

for i in range(0, len(xs)):
    xs[i] -= xmin - 1
    ys[i] -= ymin - 1
    zs[i] -= zmin - 1

xmax = max(xs)
ymax = max(ys)
zmax = max(zs)


#x, y, z = np.indices((xmax + 1, ymax + 1, zmax + 1))

n_voxels = np.zeros((xmax + 2, ymax + 2, zmax + 2), dtype=bool)

for i in range(0, len(xs)):
    n_voxels[xs[i], ys[i], zs[i]] = True

#facecolors = np.where(n_voxels, '#FFD65DC0', '#7A88CCC0')
#edgecolors = np.where(n_voxels, '#BFAB6E', '#7D84A6')
#filled = np.ones(n_voxels.shape)

#x, y, z = np.indices(np.array(filled.shape) + 1).astype(float) // 2

cols = ["#ff0000", "#00ff00", "#0000ff", "#ffff00", "#00ffff", "#ff00ff"]

colors = np.empty(n_voxels.shape, dtype=object)
for i in range(0, len(xs)):
    colors[xs[i], ys[i], zs[i]] = cols[faces[i] - 1]

ax = plt.figure().add_subplot(projection='3d')

ax.set_xlabel('X')
ax.set_ylabel('Y')
ax.set_zlabel('Z')

ax.set_xlim(0, xmax + 2)
ax.set_ylim(0, ymax + 2)
ax.set_zlim(0, zmax + 2)

ax.view_init(30, 30, 0, vertical_axis='y')

#ax.voxels(x, y, z, filled, facecolors=facecolors, edgecolors=edgecolors)
ax.voxels(n_voxels, facecolors=colors, edgecolor='k')
ax.set_aspect('equal')
ax.invert_yaxis()

#ax.scatter(xs, ys, zs, marker='X')


plt.savefig("plot.png")
