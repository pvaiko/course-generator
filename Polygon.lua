--- 2D Polygon
--
Polygon = {}
Polygon.__index = function( t, k ) 
  if type( k ) == "number" then 
    print( string.format("**getting number index %d, returning %d, size = %d", k, t.getIndex( t, k ), #t))
    return t[ t.getIndex( t, k )]
  else
    --print( string.format("**getting index %s", tostring( k )))
    return Polygon[ k ]
  end
end

--- Polygon constructor.
-- Integer indices are the vertices of the polygon
function Polygon:new( vertices )
  local newPolygon = { table.unpack( vertices )}
  return setmetatable( newPolygon, self )
end

local function addToDirectionStats( directionStats, angle, length )
  local width = 10 
  local range = math.floor( math.deg( angle ) / width ) * width + width / 2
  if directionStats[ range ] then  
    directionStats[ range ].length = directionStats[ range ].length + length
  else
    directionStats[ range ] = { length=length, dirs={}}
  end
  table.insert( directionStats[ range ].dirs, math.deg( angle ))
end

--- Trying to figure out in which direction 
-- the field is the longest.
local function getBestDirection( directionStats )
  local best = { range = 0, length = 0 }
  for range, stats in pairs( directionStats ) do
    if stats.length >= best.length then 
      best.length = stats.length
      best.range = range
    end
  end
  local sum = 0
  for i, dir in ipairs( directionStats[ best.range ].dirs ) do
    sum = sum + dir
  end
  best.dir = math.floor( sum / #directionStats[ best.range ].dirs)
  return best
end

--- Calculate angles, edges, etc. for the polygon and its vertices
--
function Polygon:calculateData()
  local directionStats = {}
  local dAngle = 0
  local shortestEdgeLength = 1000
  for i, point in ipairs( self ) do
    local pp, cp, np = self:get( i - 1 ), self:get( i ), self:get( i + 1 )
    -- vector from the previous to the next point
    local dx = np.x - pp.x 
    local dy = np.y - pp.y
    local angle, length = toPolar( dx, dy )
    self[ i ].tangent = { angle=angle, length=length, dx=dx, dy=dy }
    -- vector from the previous to this point
    dx = cp.x - pp.x
    dy = cp.y - pp.y
    angle, length = toPolar( dx, dy )
    self[ i ].prevEdge = { from={ x=pp.x, y=pp.y} , to={ x=cp.x, y=cp.y }, angle=angle, length=length, dx=dx, dy=dy }
    -- vector from this to the next point 
    dx = np.x - cp.x
    dy = np.y - cp.y
    angle, length = toPolar( dx, dy )
    self[ i ].nextEdge = { from = { x=cp.x, y=cp.y }, to={x=np.x, y=np.y}, angle=angle, length=length, dx=dx, dy=dy }
    if length < shortestEdgeLength then shortestEdgeLength = length end
    -- detect clockwise/counterclockwise direction 
    if pp.prevEdge and cp.prevEdge then
      if pp.prevEdge.angle and cp.prevEdge.angle then
        dAngle = dAngle + getDeltaAngle( cp.prevEdge.angle, pp.prevEdge.angle )
      end
    end
    addToDirectionStats( directionStats, angle, length )
  end
  self.bestDirection = getBestDirection( directionStats )
  self.isClockwise = dAngle > 0
  self.shortestEdgeLength = shortestEdgeLength
  self.boundingBox = getBoundingBox( self )
end

--- handle negative indices by circling back to 
-- the end of the polygon
function Polygon:get( index )
  if index > #self then
    return self[ index - #self ]
  elseif index > 0 then
    return self[ index ]
  elseif index == 0 then
    return self[ #self ]
  else
    return self[ #self + index ]
  end
end
