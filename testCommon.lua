--- Unit test helper functions

function assertEquals( a, b )
  local epsilon = 0.00001
  if not ( a < ( b + epsilon ) and a > ( b - epsilon )) then
    if course then printPoints( course ) end
    assert( false )
  end
end

function assertFalse( x )
  if x then
    if course then printPoints( course ) end
    assert( false )
  end
end

function point( x, y )
  return { x = x, y = y, trackNumber = 1 }
end
 
function printPoints( points )
  for i, p in ipairs( points ) do
    print( string.format( '%d %1.1f %1.1f', i, p.x, p.y ))
  end
end
