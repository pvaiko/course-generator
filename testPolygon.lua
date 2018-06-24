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

local p1 = Polyline:new( { point( 1, 0 ), point( 2, 0 ), point( 3.5, 0 ), point( 4, 0 ) })
local p2 = Polyline:new( { point( 3, 3 ), point( 3, 2 ), point( 3, 1 ), point( 3, -1 ) })
p1:appendLine(p2, 2)
assertEquals(p1[1].x, 1)
assertEquals(p1[1].y, 0)

assertEquals(p1[2].x, 2)
assertEquals(p1[2].y, 0)

assertEquals(p1[3].x, 3)
assertEquals(p1[3].y, 0)

assertEquals(p1[4].x, 3)
assertEquals(p1[4].y, 1)

assertEquals(p1[5].x, 3)
assertEquals(p1[5].y, 2)

assertEquals(p1[6].x, 3)
assertEquals(p1[6].y, 3)

local p1 = Polyline:new( { point( 1, 0 ), point( 2, 0 ), point( 2.5, 0 ), point( 2.7, 0 ) })
local p2 = Polyline:new( { point( 3, 3 ), point( 3, 2 ), point( 3, 1 ), point( 3, -1 ) })
p1:appendLine(p2,2)
print(p1)
assertEquals(p1[1].x, 1)
assertEquals(p1[1].y, 0)

assertEquals(p1[2].x, 2)
assertEquals(p1[2].y, 0)

assertEquals(p1[3].x, 2.5)
assertEquals(p1[3].y, 0)

assertEquals(p1[4].x, 2.7)
assertEquals(p1[4].y, 0)

assertEquals(p1[5].x, 3)
assertEquals(p1[5].y, 0)

assertEquals(p1[6].x, 3)
assertEquals(p1[6].y, 1)

assertEquals(p1[7].x, 3)
assertEquals(p1[7].y, 2)

assertEquals(p1[8].x, 3)
assertEquals(p1[8].y, 3)


polyline:calculateData()

n = 0
for i, edge in polyline:edgeIterator() do
	n = n + 1
end
-- one less edges than vertices if it is a line
assertEquals(n, 3)

polyline[ 3 ].turnStart = true
polyline[ 4 ].turnEnd = true

assertFalse( polyline:hasTurnWaypoint( polyline:iterator( 1, 2 )))
assertTrue( polyline:hasTurnWaypoint())
assertFalse( polyline:hasTurnWaypoint( polyline:iterator( 2, 1, -1 )))
assertTrue( polyline:hasTurnWaypoint( polyline:iterator( 1, 3 )))
assertTrue( polyline:hasTurnWaypoint( polyline:iterator( 3, 4 )))

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
end
assertEquals( n, 6 )
assertEquals( lastI, 1 )

polygon:calculateData()

n = 0
for i, edge in polygon:edgeIterator() do
	n = n + 1
end
-- same number of edges as vertices if it is a polygon
assertEquals(n, 4)


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
print(polygon)
local polygon = Polygon:new( { point( 1, 0 ), point( 2, 0 ), point( 3, 0 ), point( 4, 0 ) })
local p2 = Polygon:copy(polygon)
assertEquals( polygon[ 1 ].x, 1 )
assertEquals( polygon[ 2 ].x, 2 )
assertEquals( polygon[ 4 ].x, 4 )
assertEquals( p2[ 1 ].x, 1 )
assertEquals( p2[ 2 ].x, 2 )
assertEquals( p2[ 4 ].x, 4 )
p2:translate(1,1)
assertEquals( polygon[ 1 ].x, 1 )
assertEquals( polygon[ 2 ].x, 2 )
assertEquals( polygon[ 4 ].x, 4 )
assertEquals( p2[ 1 ].x, 2 )
assertEquals( p2[ 1 ].y, 1 )
assertEquals( p2[ 2 ].x, 3 )
assertEquals( p2[ 4 ].x, 5 )
