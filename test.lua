require( "geo" )

function eq( a, b )
  local epsilon = 0.00001
  return a < ( b + epsilon ) and a > ( b - epsilon )
end
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

epsilon = 0.001
point = addPolarVectorToPoint( 1, 1, 0, 1 ) 
assert( point.x == 2 and point.y == 1, string.format( "Got %d, %d", point.x, point.y ))

point = addPolarVectorToPoint( 0, 0, math.rad( 90 ), 1 )
assert( math.abs(point.x) < epsilon and point.y == 1, string.format( "Got %d, %d", point.x, point.y ))
point = addPolarVectorToPoint( 0, 0, math.rad( 180 ), 1 )
assert( point.x == -1 and math.abs(point.y) < epsilon, string.format( "Got %d, %d", point.x, point.y ))
point = addPolarVectorToPoint( 0, 0, math.rad( -90 ), 1 )
assert( math.abs(point.x) < epsilon and point.y == -1, string.format( "Got %d, %d", point.x, point.y ))

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
