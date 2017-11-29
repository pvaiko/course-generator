require( 'courseplay/course-generator/geo' )
require( 'testCommon')

local polygon = Polygon:new( { point( 1, 0 ), point( 2, 0 ), point( 3, 0 ), point( 4, 0 ) })
assertEquals( polygon[ 1 ].x, 1 )
assertEquals( polygon[ 0 ].x, 4 )
assertEquals( polygon[ -1 ].x, 3 )
assertEquals( polygon[ 5 ].x, 1 )
assertEquals( polygon[ 9 ].x, 1 )
assertEquals( polygon[ 6 ].x, 2 )

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
