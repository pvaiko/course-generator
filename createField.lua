--
-- Created by IntelliJ IDEA.
-- User: nyovape1
-- Date: 11/23/2017
-- Time: 5:18 PM
-- To change this template use File | Settings | File Templates.
--

print( '<CPFields>\n<field fieldNum="1" numPoints="84">' )

local i, x, y = 1, -120, -100

for j = 1, 22 do
  print( string.format( '<point%d pos="%d 0 %d"/>', i, x, y ))
  i = i + 1
  x = x + 10
end

for j = 1, 20 do
  print( string.format( '<point%d pos="%d 0 %d"/>', i, x, y ))
  i = i + 1
  y = y + 10
end

for j = 1, 22 do
  print( string.format( '<point%d pos="%d 0 %d"/>', i, x, y ))
  i = i + 1
  x = x - 10
end

for j = 1, 20 do
  print( string.format( '<point%d pos="%d 0 %d"/>', i, x, y ))
  i = i + 1
  y = y - 10
end


i, x, y = 1, -20, -20

for j = 1, 41 do
  x = -20
  for k = 1, 41 do
    if  x < -10 or y < 5 or ( x > 0 and x < 10 and y < 15 )  then
      print( string.format( '<islandNode%d pos="%d %d"/>', i, x, y ))
      i = i + 1
    end
    x = x + 1
  end
  y = y + 1
end

print( '</field>\n</CPFields>' )
