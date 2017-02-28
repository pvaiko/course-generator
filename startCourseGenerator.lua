--- Find saved Courseplay fieldwork courses, prompt the user
--  to select one to optimize.
--  Create a copy of the selected course, enter it into the courseManager.xml
--  file and then open the course generator with the copied course.
--
--  There, you can set course generation paramteres, generate and check the 
--  course and finally, save it.
--
--  The new course should be available in the game, with the name
--  (Customized) original name
--
require( 'file' )

-- generated courses will be prefixed with this string
prefix="(Customized)"

managerFileName="courseManager.xml"
if not arg[ 1 ] then 
  print( "Usage: lua startCourseGenerator.lua <courseplay save directory for a map>")
  return 
end

print( arg[1])

dir =  arg[ 1 ] 
managerFileFullPath =  dir .. "\\" .. managerFileName
managerFile = io.open( managerFileFullPath, "r" )
if not managerFile then
  print( string.format( "Can't open %s.", managerFileFullPath ))
  return
end

-- gather a list of saved courses
savedCourses, nextFreeId, nextFreeSequence = getSavedCourses( managerFile )
managerFile:close()

print()

for id, course in pairs( savedCourses ) do
  print( string.format( " [ %d ] - '%s' (%s)", course.id, course.name, course.fileName ))
end
print( string.format( "\nEnter number ( %d - %d ) for the selected course or 0 (zero) to exit\n", 1, #savedCourses ))

while true do
  selectedId = io.stdin:read( "*n" )
  if selectedId == 0 then return end
  if savedCourses[ selectedId ] ~= nil then
    -- not sure why this is needed but if I don't do this
    -- the next stdin read won't wait
    io.stdin:read()
    break
  end
end

local selectedName = savedCourses[ selectedId ].name
local newCourse = {}

if string.match( selectedName, prefix ) then
  -- already customized, don't create new
  alreadyCustomized = true
  newCourse = savedCourses[ selectedId ]
  print( string.format( [[You have selected '%s'. This seems to be a course customized
                          already. No new course will be created]], selectedName ))
else
  newCourse = { id=nextFreeId, 
                name= prefix .. " " .. selectedName,
                fileName=string.format( "courseStorage%04d.xml", nextFreeSequence )}
  print( string.format( "You have selected '%s'. Will copy it to a new course named '%s'", 
                        selectedName, newCourse.name ))
  print( string.format( "Is it ok to create '%s (%s)?' [y/n]" , newCourse.name, newCourse.fileName ))
  io.flush()
  local answer = io.stdin:read()
  if answer ~= "y" and answer ~= "Y" then
    return
  end
  copyCourse( dir, savedCourses[ selectedId ], newCourse, managerFileName )
end

-- finally, start the course generator with the new saved course file

os.execute( 'LOVE\\love.exe . "' .. dir .. "\\" .. newCourse.fileName .. '"' )
