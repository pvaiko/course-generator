---
--- Just like the Giants DebugUtil but draw debug lines/nodes on LOVE
---
DebugUtil = {}

function DebugUtil.drawDebugLine(ax, ay, az, bx, by, bz, r, g, b)
	DebugUtil.drawLine(ax, ay, az, r, g, b, bx, by, bz)
end

function DebugUtil.drawLine(ax, ay, az, r, g, b, bx, by, bz)
	love.graphics.setColor(r, g, b)
	love.graphics.line(az, ax, bz, bx)
end

function DebugUtil.drawDebugNode(node, text)
	local x, y, z = getWorldTranslation(node)
	love.graphics.setColor(1, 1, 0)
	love.graphics.setLineWidth(0.1)
	love.graphics.line(z - 0.2, x, z + 0.2, x)
	love.graphics.line(z, x - 0.2, z, x + 0.2)
	love.graphics.print(text, z, x, 0, 0.04, -0.04)
end