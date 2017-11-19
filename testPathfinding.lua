dofile( 'courseGenerator.lua' )
dofile( 'track.lua' )
dofile( 'file.lua' )
dofile( 'headland.lua' )
dofile( 'center.lua' )
dofile( 'geo.lua' )
dofile( 'bspline.lua' )
dofile( 'pathfinder.lua' )
dofile( 'a-star.lua' )

--- add some area with fruit for tests
function testAddFruit( grid, polygon )
  for y, row in ipairs( grid.map ) do
    for x, index in pairs( row ) do
      if x > 1 and x < #row and y > 1 and y < #grid.map then
        grid[ index ].hasFruit = true
      end
    end
  end
end

function testAddFruitGridDistanceFromBoundary( grid, polygon )
  local distance = 1
  for y, row in ipairs( grid.map ) do
    for x, index in pairs( row ) do
      if x > distance + 1 and x <= #row - distance and y > distance and y <= #grid.map - distance then
        grid[ index ].hasFruit = true
      end
    end
  end
end

savedFields = loadSavedFields( "testFields.xml" ) 
field = savedFields[ 1 ]
gridSpacing = 4.1
local path = {}
path.from = {}
path.to = {}
--
-- From one corner to the other
path.from.x = -100 
path.from.y = -100
path.to.x = 100
path.to.y = 100
now = os.clock()
path.course, grid = pathFinder.findPath(  pointToXz( path.from ), pointToXz( path.to ), pointsToCxCz( field.boundary ), gridSpacing, testAddFruitGridDistanceFromBoundary )
runTime = os.clock() - now  
print( string.format( "Pathfinding ran for %.2f seconds", runTime - now ))
io.stdout:flush()
assert( path.course )
assert( runTime < 0.5 )

-- From one corner to outside of the field
path.from.x = -100 
path.from.y = -100
path.to.x = 200
path.to.y = 100
now = os.clock()
path.course, grid = pathFinder.findPath(  pointToXz( path.from ), pointToXz( path.to ), pointsToCxCz( field.boundary ), gridSpacing, testAddFruitGridDistanceFromBoundary )
runTime = os.clock() - now  
print( string.format( "Pathfinding ran for %.2f seconds", runTime - now ))
io.stdout:flush()
assert( path.course == nil )
assert( runTime < 0.5 )

-- From one corner to the middle, should fail fast
path.from.x = -100 
path.from.y = -100
path.to.x = 0
path.to.y = 0 
now = os.clock()
path.course, grid = pathFinder.findPath(  pointToXz( path.from ), pointToXz( path.to ), pointsToCxCz( field.boundary ), gridSpacing, testAddFruitGridDistanceFromBoundary )
runTime = os.clock() - now  
print( string.format( "Pathfinding ran for %.2f seconds", runTime ))
io.stdout:flush()
assert( path.course == nil )
assert( runTime < 0.5 )

-- From one corner into the fruit, should fail fast
path.from.x = -100 
path.from.y = -100
path.to.x = 50
path.to.y = 50 
now = os.clock()
path.course, grid = pathFinder.findPath(  pointToXz( path.from ), pointToXz( path.to ), pointsToCxCz( field.boundary ), gridSpacing, testAddFruitGridDistanceFromBoundary )
runTime = os.clock() - now  
print( string.format( "Pathfinding ran for %.2f seconds", runTime ))
io.stdout:flush()
assert( path.course == nil )
assert( runTime < 0.5 )

-- From just outside the field 
path.from.x = -90 
path.from.y = -103
path.to.x = 86
path.to.y = 86 
now = os.clock()
path.course, grid = pathFinder.findPath(  pointToXz( path.from ), pointToXz( path.to ), pointsToCxCz( field.boundary ), gridSpacing, testAddFruitGridDistanceFromBoundary )
runTime = os.clock() - now  
print( string.format( "Pathfinding ran for %.2f seconds", runTime ))
io.stdout:flush()
assert( path.course )
assert( runTime < 0.5 )

-- From well outside the field  into the fruit, should fail fast
path.from.x = -200 
path.from.y = -100
path.to.x = 50
path.to.y = 50 
now = os.clock()
path.course, grid = pathFinder.findPath(  pointToXz( path.from ), pointToXz( path.to ), pointsToCxCz( field.boundary ), gridSpacing, testAddFruitGridDistanceFromBoundary )
runTime = os.clock() - now  
print( string.format( "Pathfinding ran for %.2f seconds", runTime ))
io.stdout:flush()
assert( path.course == nil )
assert( runTime < 0.5 )

