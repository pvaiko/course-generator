--- 2D point
-- 
Point = {}

local Point_mt = cgClass( Point )

function Point:new( x, y )
 newPoint = { x = x, y = y } 
 return setmetatable( newPoint, Point_mt )
end

function Point:toPolar()
  local length = math.sqrt( self.x * self.x + self.y * self.y )
  local bigEnough = 1000
  if ( x == 0 ) or ( math.abs( self.y/self.x ) > bigEnough ) then
    -- pi/2 or -pi/2
    if self.y >= 0 then 
      return math.pi / 2, length  -- north
    else 
      return - math.pi / 2, length -- south
    end 
  else
    return math.atan2( self.y, self.x ), length 
  end
end
    
function Point:addPolarVector( angle, length )
  return Point:new( self.x + length * math.cos( angle ),
                    self.y + length * math.sin( angle ))
end
