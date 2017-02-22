require( "geo" )
require( "track" )
require( "file" )
require( "Pickle" )

function eq( a, b )
  local epsilon = 0.00001
  return a < ( b + epsilon ) and a > ( b - epsilon )
end
--
--------------------------------------------------------------
-- Polygon iterator
--------------------------------------------------------------
t = { 1, 2, 3, 4 }
r = {}
for i, val in polygonIterator( t, 1, 4, 1 ) do
  table.insert( r, i ) 
end
assert( #r == #t )
assert( r[ 1 ] == 1, r[ 2 ] == 2, r[ 3 ] == 3, r[ 4 ] == 4 )

r = {}
for i, val in polygonIterator( t, 4, 1, -1 ) do
  table.insert( r, i ) 
end
assert( #r == #t )
assert( r[ 1 ] == 4, r[ 2 ] == 3, r[ 3 ] == 2, r[ 4 ] == 1 )

r = {}
for i, val in polygonIterator( t, 2, 1, 1 ) do
  table.insert( r, i ) 
end
assert( #r == #t )
assert( r[ 1 ] == 2, r[ 2 ] == 3, r[ 3 ] == 4, r[ 4 ] == 1 )

r = {}
for i, val in polygonIterator( t, 2, 3, -1 ) do
  table.insert( r, i ) 
end
assert( #r == #t )
assert( r[ 1 ] == 2, r[ 2 ] == 1, r[ 3 ] == 4, r[ 4 ] == 3 )

--------------------------------------------------------------
-- toPolar
--------------------------------------------------------------
a, l = toPolar( 3, 4 )
assert( l == 5, "Got " .. l  )
a, l = toPolar( -3, 4 )
assert( l == 5, "Got " .. l  )
assert( math.deg( toPolar( 1, 1 )) == 45)
assert( math.deg( toPolar( -1, 1 )) == 135)
assert( math.deg( toPolar( -1, -1 )) == -135)
assert( math.deg( toPolar( 1, -1 )) == -45)

assert( math.deg( toPolar( 1, 0 )) == 0)
assert( math.deg( toPolar( 0, 1 )) == 90)
assert( math.deg( toPolar( -1, 0 )) == 180 )
assert( math.deg( toPolar( 0, -1 )) == -90 )

--------------------------------------------------------------
-- addPolarVectorToPoint
--------------------------------------------------------------
epsilon = 0.001
point = { x = 1, y = 1 }
point = addPolarVectorToPoint( point, 0, 1 ) 
assert( point.x == 2 and point.y == 1, string.format( "Got %d, %d", point.x, point.y ))

point = { x = 0, y = 0 }
point = addPolarVectorToPoint( point, math.rad( 90 ), 1 )
assert( math.abs(point.x) < epsilon and point.y == 1, string.format( "Got %d, %d", point.x, point.y ))
point = { x = 0, y = 0 }
point = addPolarVectorToPoint( point, math.rad( 180 ), 1 )
assert( point.x == -1 and math.abs(point.y) < epsilon, string.format( "Got %d, %d", point.x, point.y ))
point = { x = 0, y = 0 }
point = addPolarVectorToPoint( point, math.rad( -90 ), 1 )
assert( math.abs(point.x) < epsilon and point.y == -1, string.format( "Got %d, %d", point.x, point.y ))

--------------------------------------------------------------
-- getAverageAngle
--------------------------------------------------------------
avg = math.deg( getAverageAngle( math.rad( 10 ), math.rad( 50 )))
assert( eq( avg, 30 ), "Got " ..  avg );
avg = math.deg( getAverageAngle( math.rad( -10 ), math.rad( -20 )))
assert( eq( avg, -15), "Got " ..  avg );
avg = math.deg( getAverageAngle( math.rad( -140 ), math.rad( 140 )))
assert( eq( avg, 180), "Got " ..  avg );
avg = math.deg( getAverageAngle( math.rad( -178 ), math.rad( 176 )))
assert( eq( avg, 179), "Got " ..  avg );
avg = math.deg( getAverageAngle( math.rad( -10 ), math.rad( 30 )))
assert( eq( avg, 10), "Got " ..  avg );
avg = math.deg( getAverageAngle( math.rad( -89 ), math.rad( 89 )))
assert( eq( avg, 0), "Got " ..  avg );
avg = math.deg( getAverageAngle( math.rad( -89 ), math.rad( 91 )))
assert( eq( avg, 1), "Got " ..  avg );

local t = { name='hello', loc = {{x=1,y=2},{x=3,y=4}}}

local f = io.output( "test.pickle" )
io.write( pickle( t )) 
io.close( f )

io.input( "test.pickle" )
local r = unpickle( io.read( "*all" ))
assert( r.loc[ 1 ].x == 1 and r.loc[ 1 ].y == 2 )


--------------------------------------------------------------
-- reverse table
--------------------------------------------------------------

t = { 1, 2, 3, 4 }
r = reverse( t )
assert( #r == #t )
assert( r[ 1 ] == 4, r[ 2 ] == 3, r[ 3 ] == 2, r[ 4 ] == 1 )



--------------------------------------------------------------
-- Smoke test
--------------------------------------------------------------

marks = {}
for i, fieldName in ipairs( { "8", "9", "23" }) do
  for width = 3, 2 do
    print( string.format( "\nGenerating course for field %s with width %d", fieldName, width ))
    local field = loadFieldFromPickle( fieldName )
    generateCourseForField( field, width, 5, false )
    field = loadFieldFromPickle( fieldName .. "_reversed" )
    generateCourseForField( field, width, 5, false )
  end
end


local fileName = "courses/courseStorage0004.xml"
--local field = loadFieldFromSavedCourse( fileName )
--calculatePolygonData( field.boundary )
--field.vehicle = { location = field.boundary[ 1 ], heading = field.boundary[ 2 ].fromEdge.angle - math.pi / 2 }

  field = {}
  field = loadFieldFromPickle(23)
  field.nHeadlandPasses = 5
  field.width = 4.4
  field.isClockwise = "true"

generateCourseForField( field, field.width, field.nHeadlandPasses, true )
writeCourseToFile( field, fileName ) 

