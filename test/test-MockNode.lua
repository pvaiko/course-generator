
if love == nil then
	package.cpath = package.cpath .. ';C:/Users/nyovape1/AppData/Local/JetBrains/Toolbox/apps/IDEA-U/ch-0/212.5457.46.plugins/EmmyLua/classes/debugger/emmy/windows/x86/?.dll'
	local dbg = require('emmy_core')
	dbg.tcpConnect('localhost', 9966)
end

dofile('MockNode.lua')

function assertFloat(a, b)
	assert(math.abs(a - b) < 0.01)
end

---
--- Test the MockNode transformation functions
--- To validate these tests, jsut copy/paste it starting from here, into the Giants script editor and run it.
--- In the Giants editor, these calls are executed by the Giants engine and should deliver the same results.
---

local node = createTransformGroup('test')
setTranslation(node, 10, 0, 11)
local x, y, z = getWorldTranslation(node)
assertFloat(x, 10)
assertFloat(y, 0)
assertFloat(z, 11)

x, y, z = localToWorld(node, 0, 0, 0)
assertFloat(x, 10)
assertFloat(y, 0)
assertFloat(z, 11)

local dx, dy, dz = worldToLocal(node, 10, 0, 11)
assertFloat(dx, 0)
assertFloat(dy, 0)
assertFloat(dz, 0)

x, y, z = localToWorld(node, 0, 0, 1)
assertFloat(x, 10)
assertFloat(y, 0)
assertFloat(z, 12)

dx, dy, dz = worldToLocal(node, 10, 0, 12)
assertFloat(dx, 0)
assertFloat(dy, 0)
assertFloat(dz, 1)

dx, dy, dz = worldToLocal(node, 10, 0, 10)
assertFloat(dx, 0)
assertFloat(dy, 0)
assertFloat(dz, -1)

dx, dy, dz = worldToLocal(node, 11, 0, 10)
assertFloat(dx, 1)
assertFloat(dy, 0)
assertFloat(dz, -1)

x, y, z = localToWorld(node, 1, 0, 0)
assertFloat(x, 11)
assertFloat(y, 0)
assertFloat(z, 11)


x, y, z = localToWorld(node, 1, 0, 1)
assertFloat(x, 11)
assertFloat(y, 0)
assertFloat(z, 12)

setRotation(node, 0, math.pi, 0)
x, y, z = getWorldTranslation(node)
assertFloat(x, 10)
assertFloat(y, 0)
assertFloat(z, 11)

x, y, z = localToWorld(node, 0, 0, 1)
assertFloat(x, 10)
assertFloat(y, 0)
assertFloat(z, 10)

setRotation(node, 0, math.pi / 2, 0)
x, y, z = localToWorld(node, 0, 0, 1)
assertFloat(x, 11)
assertFloat(y, 0)
assertFloat(z, 11)

setRotation(node, 0, -math.pi / 2, 0)
x, y, z = localToWorld(node, 0, 0, 1)
assertFloat(x, 9)
assertFloat(y, 0)
assertFloat(z, 11)

dx, dy, dz = worldToLocal(node, 9, 0, 11)
assertFloat(dx, 0)
assertFloat(dy, 0)
assertFloat(dz, 1)

x, y, z = localToWorld(node, 1, 0, 1)
assertFloat(x, 9)
assertFloat(y, 0)
assertFloat(z, 12)

local child = createTransformGroup('child')
link(node, child)
x, y, z = localToWorld(child, 0, 0, 0)
assertFloat(x, 10)
assertFloat(y, 0)
assertFloat(z, 11)

x, y, z = localToWorld(child, 1, 0, 1)
assertFloat(x, 9)
assertFloat(y, 0)
assertFloat(z, 12)

setTranslation(child, 0, 0, 1)
x, y, z = getWorldTranslation(child)
assertFloat(x, 9)
assertFloat(y, 0)
assertFloat(z, 11)

x, y, z = localToWorld(child, 0, 0, 0)
assertFloat(x, 9)
assertFloat(y, 0)
assertFloat(z, 11)

x, y, z = localToWorld(child, 1, 0, 1)
assertFloat(x, 8)
assertFloat(y, 0)
assertFloat(z, 12)

local grandChild = createTransformGroup('grandChild')
link(child, grandChild)
x, y, z = localToWorld(grandChild, 1, 0, 1)
assertFloat(x, 8)
assertFloat(y, 0)
assertFloat(z, 12)

setTranslation(grandChild, 0, 0, 1)
x, y, z = getWorldTranslation(grandChild)
assertFloat(x, 8)
assertFloat(y, 0)
assertFloat(z, 11)
x, y, z = localToWorld(grandChild, 1, 0, 1)
assertFloat(x, 7)
assertFloat(y, 0)
assertFloat(z, 12)

setRotation(grandChild, 0, math.pi / 2, 0)
x, y, z = getWorldTranslation(grandChild)
assertFloat(x, 8)
assertFloat(y, 0)
assertFloat(z, 11)

x, y, z = localToWorld(grandChild, 1, 0, 1)
assertFloat(x, 9)
assertFloat(y, 0)
assertFloat(z, 12)
