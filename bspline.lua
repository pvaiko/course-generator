-- http://stackoverflow.com/questions/29612584/creating-cubic-and-or-quadratic-bezier-curves-to-fit-a-path
--
require( "geo" )
angleThreshold = math.pi / 10
-- insert a point in the middle of each edge.
function _refine( points ) 
  local ix = function( a ) return getPolygonIndex( points, a ) end
  -- points = [points[0]].concat(points).concat(points[points.length-1]);
  local refined = {}
  local rIx = 1;
  for i = 1, #points do 
    local point = points[ i ];
    refined[ rIx ] = point
    if points[ ix( i + 1 )] then 
      if( isSharpTurn( points[ i ].edge, points[ ix( i + 1 )].edge )) then 
        -- insert points only when there is really a curve here
        -- table.insert( marks, points[ i ])
        local x, y =  _mid( point, points[ ix( i + 1 )]);
        rIx = rIx + 1
        refined[ rIx ] = { x = x, y = y }
      end
    end
    rIx = rIx + 1;
  end
  return refined;
end

-- insert point in the middle of each edge and remove the old points.
function _dual( points ) 
  local ix = function( a ) return getPolygonIndex( points, a ) end
  local dualed = {}
  local index = 1
  for i = 1, #points do
    point = points[ i ];
    if points[ ix( index + 1 )] then
      x, y = _mid( point, points[ ix( index + 1 )]);
      dualed[ index ] = { x = x, y = y }
    end
    index = index + 1;
  end
  return dualed;
end

-- move the current point a bit towards the previous and next. 
function _tuck( points, s )
  local tucked = {}
  local index = 1
  local ix = function( a ) return getPolygonIndex( points, a ) end
  for i, point in ipairs( points ) do
    local pp, cp, np = points[ ix( i - 1 )], points[ ix( i )], points[ ix( i + 1 )]
    -- tuck points only when there is really a curve here
    if ( isSharpTurn( points[ i ].edge, points[ ix( i + 1 )].edge )) then
      -- mid point between the previous and next
      local midPNx, midPNy = _mid( pp, np )
      -- vector from current point to mid point
      local mx, my = midPNx - cp.x, midPNy - cp.y
      -- move current point towards (or away from) the midpoint by the factor s
      tucked[ index ] = { x=cp.x + mx * s, y=cp.y + my * s }
    else
      tucked[ index ] = cp
    end
    index = index + 1
  end
  return tucked
end

function _mid( a, b ) 
  return a.x + (( b.x - a.x ) / 2 ),
         a.y + (( b.y - a.y ) / 2 )
end

function isSharpTurn( a, b )
    local da = getDeltaAngle( a.angle, b.angle )
    return math.abs( da ) > angleThreshold
end

function smooth(points, order) 
  if ( order <= 0  ) then
    return points
  else
    local refined = _refine( points )
    calculatePolygonData( refined )
    refined = _tuck( refined, 0.5 )
    calculatePolygonData( refined )
    refined = _tuck( refined, -0.15 )
    calculatePolygonData( refined )
    return smooth( refined, order - 1 );
  end
end
