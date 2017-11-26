--
-- Created by IntelliJ IDEA.
-- User: nyovape1
-- Date: 11/24/2017
-- Time: 8:07 AM
-- To change this template use File | Settings | File Templates.
--
dofile( 'include.lua' )

marks = {}

local minSmoothingAngleDeg = 30
local minHeadlandTurnAngleDeg = 60
local doSmooth = true
local course

local function p( x, y ) 
  return { x = x, y = y, trackNumber = 1 }
end

local function printCourse( course )
  for i, p in ipairs( course ) do
    print( string.format( '%d %1.1f %1.1f', i, p.x, p.y ))
  end
end

local function assertEquals( a, b )
  local epsilon = 0.00001
  if not ( a < ( b + epsilon ) and a > ( b - epsilon )) then
    printCourse( course )
    assert( false )
  end
end

local savedFields = loadSavedFields( 'testFields.xml' )
local field = savedFields[ 1 ]

field.width = 5
field.nHeadlandPasses = 2

setupIslands( field, 2, 6, 0.5, math.rad( minSmoothingAngleDeg ), math.rad( minHeadlandTurnAngleDeg ), doSmooth )

assertEquals( #field.islands , 1 )
local island = field.islands[ 1 ]
assertEquals( #island.nodes , 171 )

print( '\n*** course with multiple waypoints on the island' )
-- x | x x x x | x x
-- 1   2 3 4 5   6 7
course = { p(-25, 0 ), p( -15, 0 ), p( -5, 0 ), p(5, 0 ), p( 15, 0 ), p( 25, 0 ), p( 35, 0 )}
island:bypass( course )
assertEquals( #course, 87 )
assertEquals( course[ 2 ].x , -23 )
assertEquals( course[ 45 ].y , 23 )
assertEquals( course[ 85 ].x , 23 )

print( '\n*** course with two waypoints on the island' )
-- x | x x | x x
-- 1   2 3   4 5
course = { p( -25, 0 ), p( -15, 0 ), p( 15, 0 ), p( 25, 0 ), p( 35, 0 ) }
island:bypass( course )
assertEquals( #course, 87 )
assertEquals( course[ 2 ].x , -23 )
assertEquals( course[ 45 ].y , 23 )
assertEquals( course[ 85 ].x , 23 )

print( '\n*** course with one waypoint on the island' )
-- x | x | x x
-- 1   2   3 4
course = { p( -25, 0 ), p( 0, 0 ), p( 25, 0 ), p( 35, 0 ) }
island:bypass( course )
assertEquals( #course, 87 )
assertEquals( course[ 2 ].x , -23 )
assertEquals( course[ 85 ].x , 23 )

print( '\n*** course reenters the island after one waypoint on the island' )
-- x | x | x | x x
-- 1   2   3   4 5 
course = { p( -25, -10 ), p( -15, -10), p( -5, -10 ), p( 10, -10 ), p( 35, -10 ) }
island:bypass( course )
assertEquals( #course, 52 )
assertEquals( course[ 2 ].x , -23 )
assertEquals( course[ 33 ].y , -10 )
assertEquals( course[ 42 ].y , -17 )

print( '\n*** course enters then exits the island, but exit also reenters' )
-- x | x |   | x | x x
-- 1   2       3   4  
course = { p( -25, -10 ), p( -15, -10), p( 5, -10 ), p( 25, -10 ), p( 35, -10 ) }
island:bypass( course )
-- x | x |   | x | x x
-- 1 2 3 4   5 6 7 8 9
assertEquals( #course, 36 )
assertEquals( course[ 2 ].x , -23 )
assertEquals( course[ 16 ].y , -23 )
assertEquals( course[ 33 ].x , 5 )

print( '\n*** course with no waypoint on the island' )
-- x |   | x x
-- 1 |   | 2 3
course = { p( -25, 0 ), p( 25, 0 ), p( 35, 0 ) }
island:bypass( course )
assertEquals( #course, 5 )
assertEquals( course[ 2 ].x , -23 )
assertEquals( course[ 3 ].x , 23 )
