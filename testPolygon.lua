require( 'courseplay/course-generator/geo' )
require( 'testCommon')

local polyline = Polyline:new( { point( 1, 0 ), point( 2, 0 ), point( 3, 0 ), point( 4, 0 ) })
local n = 0
local lastI = 0
for i, p in polyline:iterator() do
  n = n + 1
  lastI = i

  assertFalse( polyline[ i ] == nil )
end
assertEquals( n, 4 )
assertEquals( lastI, 4 )

n = 0
for i, p in polyline:iterator( 0, 5 ) do
  n = n + 1
  lastI = i
  local r = math.min( #polyline, math.max( 1, i ))
  assertEquals( p.x, r )
  assertFalse( polyline[ r ] == nil )
end
assertEquals( n, 4 )
assertEquals( lastI, 4 )


n = 0
for i, p in polyline:iterator( -2, 6 ) do
  n = n + 1
  lastI = i
  local r = math.min( #polyline, math.max( 1, i ))
  assertEquals( p.x, r )
  assertFalse( polyline[ r ] == nil )
end
assertEquals( n, 4 )
assertEquals( lastI, 4 )


n = 0
for i, p in polyline:iterator( 5, 0, -1 ) do
  n = n + 1
  lastI = i
  local r = math.min( #polyline, math.max( 1, i ))
  assertEquals( p.x, r )
  assertFalse( polyline[ r ] == nil )
end
assertEquals( n, 4 )
assertEquals( lastI, 1 )


n = 0
for i, p in polyline:iterator( 6, -2, -1 ) do
  n = n + 1
  lastI = i
  local r = math.min( #polyline, math.max( 1, i ))
  assertEquals( p.x, r )
  assertFalse( polyline[ r ] == nil )
end
assertEquals( n, 4 )
assertEquals( lastI, 1 )

polyline:calculateData()


local polygon = Polygon:new( { point( 1, 0 ), point( 2, 0 ), point( 3, 0 ), point( 4, 0 ) })
assertEquals( polygon[ 1 ].x, 1 )
assertEquals( polygon[ 0 ].x, 4 )
assertEquals( polygon[ -1 ].x, 3 )
assertEquals( polygon[ 5 ].x, 1 )
assertEquals( polygon[ 9 ].x, 1 )
assertEquals( polygon[ 6 ].x, 2 )

local n = 0
local lastI = 0
for i, p in polygon:iterator( 1, 4 ) do
  n = n + 1
  lastI = i
end
assertEquals( n, 4 )
assertEquals( lastI, 4 )

for i, p in polygon:iterator( 4, 1 ) do
  n = n + 1
  lastI = i
  print( i )
end
assertEquals( n, 6 )
assertEquals( lastI, 1 )

polygon[ 0 ].x = 0
assertEquals( polygon[ 0 ].x, 0 )

polygon[ 5 ].x = -1
assert( #polygon == 4 )
assertEquals( polygon[ 5 ].x, -1 )
assertEquals( polygon[ 1 ].x, -1 )

polygon[ 5 ] = point( 5, 0 )
assert( #polygon == 5 )
assertEquals( polygon[ 1 ].x, -1 )
assertEquals( polygon[ 5 ].x, 5 )
assertEquals( polygon[ 6 ].x, -1 )
polygon:calculateData()