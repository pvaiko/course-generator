require( 'Object' )
require( 'Point' )
require( 'Vertex' )
require( 'courseplay/course-generator/geo' )

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

p = Polygon:new( { Vertex:new( 1, 0 ), Vertex:new( 2, 0 ), Vertex:new( 3, 0 ), Vertex:new( 4, 0 ) })
assert( equals( p[ 1 ].x, 1 ))
assert( equals( p[ 0 ].x, 4 ))
assert( equals( p[ -1 ].x, 3 ))
assert( equals( p[ 5 ].x, 1 ))
assert( equals( p[ 9 ].x, 1 ))
assert( equals( p[ 6 ].x, 2 ))

p[ 0 ].x = 0
assert( equals( p[ 0 ].x, 0 ))

p[ 5 ].x = -1
assert( #p == 4 )
assert( equals( p[ 5 ].x, -1 ))
assert( equals( p[ 1 ].x, -1 ))
    
p[ 5 ] = Vertex:new( 5, 0 )
assert( #p == 5 )
assert( equals( p[ 1 ].x, -1 ))
assert( equals( p[ 5 ].x, 5 ))
assert( equals( p[ 6 ].x, -1 ))
--
--------------------------------------------------------------
-- Polygon iterator
--------------------------------------------------------------
local t = Polygon:new({ 1, 2, 3, 4 })

r = {}
for i, val in t:iterator() do
  table.insert( r, i )
end
assert( #r == #t )
assert( r[ 1 ] == 1, r[ 2 ] == 2, r[ 3 ] == 3, r[ 4 ] == 4 )

r = {}
for i, val in t:iterator( 1, 4, 1 ) do
  table.insert( r, i )
end
assert( #r == #t )
assert( r[ 1 ] == 1, r[ 2 ] == 2, r[ 3 ] == 3, r[ 4 ] == 4 )

r = {}
for i, val in t:iterator( 4, 1, -1 ) do
  table.insert( r, i )
end
assert( #r == #t )
assert( r[ 1 ] == 4, r[ 2 ] == 3, r[ 3 ] == 2, r[ 4 ] == 1 )

r = {}
for i, val in t:iterator( 2, 1, 1 ) do
  table.insert( r, i )
end
assert( #r == #t )
assert( r[ 1 ] == 2, r[ 2 ] == 3, r[ 3 ] == 4, r[ 4 ] == 1 )

r = {}
for i, val in t:iterator( 2, 3, -1 ) do
  table.insert( r, i )
end
assert( #r == #t )
assert( r[ 1 ] == 2, r[ 2 ] == 1, r[ 3 ] == 4, r[ 4 ] == 3 )
