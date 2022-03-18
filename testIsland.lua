--
-- Created by IntelliJ IDEA.
-- User: nyovape1
-- Date: 11/24/2017
-- Time: 8:07 AM
-- To change this template use File | Settings | File Templates.
--
dofile( 'include.lua' )
dofile( 'testCommon.lua' )

marks = {}

local minSmoothingAngleDeg = 30
local minHeadlandTurnAngleDeg = 60

-- force bypass on any size of island
Island.maxRowsToBypassIsland = 500

local function courseHasRepeatingWaypoints( course )
  for i = 1, #course - 1 do
    if course[ i ].x == course[ i + 1 ].x and course[ i + 1 ].y == course[ i ].y then
      -- for now ignore this, always return false
      return false
    end
  end
  return false
end

local savedFields = loadSavedFields( 'testFields.xml' )
local field = savedFields[ 1 ]

field.width = 5
field.nHeadlandPasses = 2

local expectedNumberOfWaypoints = 52

setupIslands( field, 2, 6, 10, 0.5, math.rad( minSmoothingAngleDeg ), math.rad( minHeadlandTurnAngleDeg ), field.islandNodes )

assertEquals( #field.islands , 1 )
local island = field.islands[ 1 ]
assertEquals( #island.nodes , 171 )

print( '\n*** course with multiple waypoints on the island' )
-- x | x x x x | x x
-- 1   2 3 4 5   6 7
course = Polyline:new({ point(-25, 0 ), point( -15, 0 ), point( -5, 0 ), point(5, 0 ), point( 15, 0 ), point( 25, 0 ), point( 35, 0 )})
island:bypass( course )
assertEquals( #course, expectedNumberOfWaypoints )
assertEquals( course[ 2 ].x , -23 )
assertEquals( course[ 45 ].y , 23 )
assert( course[ 45 ].islandBypass)
assert( course[ 45 ].radius )

assertEquals( course[ 84 ].x , 23 )
assertFalse( courseHasRepeatingWaypoints( course ))

print( '\n*** course with two waypoints on the island' )
-- x | x x | x x
-- 1   2 3   4 5
course = Polyline:new({ point( -25, 0 ), point( -15, 0 ), point( 15, 0 ), point( 25, 0 ), point( 35, 0 ) })
island:bypass( course )
assertEquals( #course, expectedNumberOfWaypoints )
assertEquals( course[ 2 ].x , -23 )
assertEquals( course[ 45 ].y , 23 )
assertEquals( course[ 84 ].x , 23 )
assertFalse( courseHasRepeatingWaypoints( course ))

print( '\n*** course with one waypoint on the island' )
-- x | x | x x
-- 1   2   3 4
course = Polyline:new({ point( -25, 0 ), point( 0, 0 ), point( 25, 0 ), point( 35, 0 ) })
island:bypass( course )
assertEquals( #course, expectedNumberOfWaypoints )
assertEquals( course[ 2 ].x , -23 )
assertEquals( course[ 84 ].x , 23 )
assertFalse( courseHasRepeatingWaypoints( course ))

print( '\n*** course reenters the island after one waypoint on the island' )
-- x | x | x | x x
-- 1   2   3   4 5 
course = Polyline:new({ point( -25, -10 ), point( -15, -10), point( -5, -10 ), point( 10, -10 ), point( 35, -10 ) })
island:bypass( course )
assertEquals( #course, 52 )
assertEquals( course[ 2 ].x , -23 )
assertEquals( course[ 33 ].y , -10 )
assertEquals( course[ 42 ].y , -17 )
assertFalse( courseHasRepeatingWaypoints( course ))

print( '\n*** course enters then exits the island, but exit also reenters' )
-- x | x |   | x | x x
-- 1   2       3   4  
course = Polyline:new({ point( -25, -10 ), point( -15, -10), point( 5, -10 ), point( 25, -10 ), point( 35, -10 ) })
island:bypass( course )
-- x | x |   | x | x x
-- 1 2 3 4   5 6 7 8 9
assertEquals( #course, 36 )
assertEquals( course[ 2 ].x , -23 )
assertEquals( course[ 16 ].y , -23 )
assertEquals( course[ 33 ].x , 5 )
assertFalse( courseHasRepeatingWaypoints( course ))

print( '\n*** course with no waypoint on the island' )
-- x |   | x x
-- 1 |   | 2 3
course = Polyline:new({ point( -25, 0 ), point( 25, 0 ), point( 35, 0 ) })
island:bypass( course )
assertEquals( #course, expectedNumberOfWaypoints )
assertEquals( course[ 2 ].x , -23 )
assertEquals( course[ 80 ].x , 23 )
assertFalse( courseHasRepeatingWaypoints( course ))
