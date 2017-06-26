require( 'Object' )
require( 'Point' )
require( 'Vertex' )
require( 'Polygon' )
require( 'geo' )

local function equals( a, b )
  local epsilon = 0.00001
  return a < ( b + epsilon ) and a > ( b - epsilon )
end

a, l = Point:new( 1, 1 ):toPolar()
assert( math.deg( a ) == 45 )
assert( l == math.sqrt( 2 ))

--------------------------------------------------------------
-- Point
--------------------------------------------------------------

a, l = Point:new( 3, 4 ):toPolar()
assert( l == 5, "Got " .. l  )
a, l = Point:new( -3, 4 ):toPolar()
assert( l == 5, "Got " .. l  )
assert( math.deg( Point:new(1,1):toPolar()) == 45)
assert( math.deg( Point:new( -1, 1 ):toPolar()) == 135)
assert( math.deg( Point:new( -1, -1 ):toPolar()) == -135)
assert( math.deg( Point:new( 1, -1 ):toPolar()) == -45)

assert( math.deg( Point:new( 1, 0 ):toPolar()) == 0)
assert( math.deg( Point:new( 0, 1 ):toPolar()) == 90)
assert( math.deg( Point:new( -1, 0 ):toPolar()) == 180 )
assert( math.deg( Point:new( 0, -1 ):toPolar()) == -90 )

o = Point:new( 1, 1 ):addPolarVector( math.rad( -135 ), math.sqrt( 2 ))
assert( equals( o.x, 0 ))
assert( equals( o.y, 0 ))

--------------------------------------------------------------
-- Polygon 
--------------------------------------------------------------
p = Polygon:new( { Vertex:new( 0, 0 ), Vertex:new( 1, 0 ), Vertex:new( 1, 1 ), Vertex:new( 0, 1 ) })
p:calculateData()

