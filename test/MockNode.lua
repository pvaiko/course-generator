--[[

A (2D only) mock for the Giants engine's node. The 3D Giants coordinates (x, y, z) are translated to
the (x, y) plane as follows x -> y, z -> x.

]]

--- A root node has no parents
---@class RootNode
RootNode = CpObject()

function RootNode:init()
end

function RootNode:getWorldTranslation()
	return 0, 0
end

function RootNode:getWorldTranslationVector()
	return Vector(0, 0)
end

function RootNode:getWorldRotation()
	return 0
end

--- A node which has a parent, by default the root node
---@class MockNode : RootNode
MockNode = CpObject(RootNode)
function MockNode:init(name)
	self.name = name
	-- a unit vector representing the y rotation
	self.rotation = Vector(1, 0)
	-- this is my translation in the world
	self.translation = Vector(0, 0)
	self.parentNode = RootNode()
end

--- Get world translation (with all the parents) in the x, y system
function MockNode:getWorldTranslationVector()
	local worldVector = self.parentNode:getWorldTranslationVector()
	local localVector = self.translation:clone()
	localVector:rotate(self.parentNode:getWorldRotation())
	return worldVector + localVector
end

function MockNode:getWorldTranslation()
	local wV = self:getWorldTranslationVector()
	return wV.x, wV.y
end

function MockNode:getWorldRotation()
	return self.rotation:heading() + self.parentNode:getWorldRotation()
end

-- this is used to create a node, return a mock Node object instead of the integer returned by the Giants engine
function createTransformGroup(name)
	return MockNode(name)
end

function entityExists(node)
	return true
end

function link(otherNode, node)
	if otherNode then
		node.parentNode = otherNode
	end
end

function unlink(node)
end

function delete(node)
end

---@param node : MockNode
function setTranslation(node, x, _, z)
	node.translation:set(z, x)
end

---@param node : MockNode
function setRotation(node, _, yRot, _)
	node.rotation:setHeading(yRot)
end

---@param node : MockNode
function getRotation(node)
	return 0, node.rotation:heading(), 0
end

function getTerrainHeightAtWorldPos()
	return 0
end

function getWorldTranslation(node)
	local x, y = node:getWorldTranslation()
	return y, 0, x
end

function getWorldRotation(node)
	local yRot = node:getWorldRotation()
	return 0, yRot, 0
end

---@param node : MockNode
function localToWorld(node, dx, dy, dz)
	local worldVector = node:getWorldTranslationVector()
	local zVector = Vector(1, 0)
	zVector:setHeading(node:getWorldRotation())
	zVector:setLength(dz)
	local xVector = Vector(1, 0)
	xVector:setHeading(node:getWorldRotation())
	xVector:rotate(math.pi / 2)
	xVector:setLength(dx)
	local worldPos = worldVector + zVector + xVector
	return worldPos.y, 0, worldPos.x
end

function worldToLocal(node, x, y, z)
	local px, py = z, x
	local wx, wy = node:getWorldTranslation()
	local dx = px - wx
	local dy = py - wy
	local yRot = node:getWorldRotation()
	local lx = math.cos(-yRot) * dx - math.sin(-yRot) * dy
	local ly = math.cos(-yRot) * dy + math.sin(-yRot) * dx
	return ly, 0, lx
end

function localToLocal()
	return 0, 0, 0
end

function localDirectionToWorld(node, dx, dy, dz)
	local v = Vector(dz, dx)
	local yRot = node:getWorldRotation()
	v:setHeading(yRot)
	return v.y, _, v.x
end
