---@class Vehicle
Vehicle = CpObject()

function Vehicle:init(x, z, yRotation)
	self.position = Point(x, z, yRotation)
	self.wheelbase = 5
	self.maxSteeringAngle = math.rad(40)
	self.steeringAngle = 0
	self.speed = 0 -- m/s
	self.maxSpeed = 5
	self.turningRadius = self.wheelbase / math.tan(self.steeringAngle)
	self.minTurningRadius = self.wheelbase / math.tan(self.maxSteeringAngle)
	self.trail = {}
	self.clock = 0
end

function Vehicle:setPosition(x, z)
	self.position.x = x
	self.position.z = z
	self.speed = 0
end

function Vehicle:setRotation(yRotation)
	self.position.yRotation = yRotation
end

---@param t Point
function Vehicle:setTarget(p)
	self.target = p
end

function Vehicle:draw()
	local left, right = -1.5, 1.5
	local triangle = { 0, left, 0, right, self.wheelbase, 0}
	love.graphics.push()
	love.graphics.translate(self.position.x, -self.position.z)
	love.graphics.rotate(self.position.yRotation )
	love.graphics.polygon( 'fill', triangle )
	love.graphics.pop()
	self:drawTrail()
end

function Vehicle:drawTrail()
	love.graphics.push()
	local ps = love.graphics.getPointSize()
	love.graphics.setPointSize(ps * 0.4)
	for _, p in ipairs(self.trail) do
		love.graphics.points(p.x, -p.z)
	end
	love.graphics.pop()
end

function Vehicle:accelerate()
	if self.speed < self.maxSpeed then
		self.speed = self.speed + 0.1
	end
end

function Vehicle:deccelerate()
	if self.speed > -self.maxSpeed then
		self.speed = self.speed - 0.1
	end
end

function Vehicle:turnLeft()
	if self.steeringAngle < self.maxSteeringAngle then
		self.steeringAngle = self.steeringAngle + math.pi / 180
	end
end

function Vehicle:turnRight()
	if self.steeringAngle > -self.maxSteeringAngle then
		self.steeringAngle = self.steeringAngle - math.pi / 180
	end
end

function Vehicle:update(dt)
	self.clock = self.clock + 1
	local distance = dt * self.speed
	self.turningRadius = self.wheelbase / math.tan(self.steeringAngle)
	self.position.yRotation = self.position.yRotation + 2 * math.asin(distance / 2 / self.turningRadius)
	self.position.x, self.position.z = self.position:localToWorld( distance, 0)
	self:updateTrail()
	self:drive()
end

function Vehicle:limit(v, limit)
	return math.max(math.min(v, limit), -limit)
end

function Vehicle:drive()
	if not self.target then return end
	-- target position in the vehicle system
	local tlx, tlz = self.position:worldToLocal(self.target.x, self.target.z)
	-- vehicle position in the target's system
	local vlx, vlz = self.target:worldToLocal(self.position.x, self.position.z)
	local headingError = self.position.yRotation - self.target.yRotation
	--self.steeringAngle = math.min(headingError, self.maxSteeringAngle)
	self.steeringAngle = self:limit(-tlz / 20, self.maxSteeringAngle)
	self.speed = self:limit(tlx / 5, self.maxSpeed)
end

function Vehicle:updateTrail()
	if self.clock % 50 == 0 then
		table.insert(self.trail, self.position:clone())
		if #self.trail > 50 then
			table.remove(self.trail, 1)
		end
	end
end