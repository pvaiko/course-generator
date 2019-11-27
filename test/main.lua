dofile( 'include.lua' )

local turnRadius = 6
local goalHeading = 0

local start = State3D(0, 0, 0 , 0)
local goal = State3D(13.5, 0, goalHeading, 0)
local dubinsPath = {}
local pathFinder = HybridAStarWithAStarInTheMiddle(20)
local done, path
local corners = {
    {x = -1000, y = -1000},
    {x = -1000, y = 1000},
    {x = 1000, y = 1000},
    {x = 1000, y = -1000},
}

local fieldPolygon = Polygon:new(corners)

function find(start, goal)
    done, path = pathFinder:start(start, goal, turnRadius, true, fieldPolygon)
    local dubinsPathDescriptor = dubins_shortest_path(start, goal, turnRadius)
    dubinsPath = dubins_path_sample_many(dubinsPathDescriptor, 1)
    print(dubinsPathDescriptor.type)
    return done, path
end

local scale, width, height = 10, 1000, 800
local xOffset, yOffset = width / scale / 2, height / scale / 2

local function debug(...)
    print(string.format(...))
end

local function drawGoal(goal)
    love.graphics.push()
    love.graphics.translate(goal.x, goal.y)
    love.graphics.rotate(goalHeading)
    local left, right = -1.5, 1.5
    local triangle = { 0, left, 0, right, 4, 0}
    love.graphics.polygon( 'fill', triangle )
    love.graphics.pop()
end

function love.load()
    love.window.setMode(1000, 800)
    love.graphics.setPointSize(3)
    find(start, goal)
end

function love.draw()
    love.graphics.scale(scale, -scale)
    love.graphics.translate(xOffset, -yOffset)


    love.graphics.setColor( 50, 50, 50 )
    love.graphics.line(-1000, 0, 1000, 0)
    love.graphics.line(0, -1000, 0, 1000)

    if pathFinder and pathFinder.nodes then
        for _, row in pairs(pathFinder.nodes.nodes) do
            for _, column in pairs(row) do
                for _, cell in pairs(column) do
                    if cell.pred == cell then
                        love.graphics.setPointSize(5)
                        love.graphics.setColor( 0, 100, 100 )
                    else
                        local range = pathFinder.nodes.highestCost - pathFinder.nodes.lowestCost
                        local color = (cell.cost - pathFinder.nodes.lowestCost) * 250 / range
                        love.graphics.setPointSize(1)
                        if cell:isClosed() or true then
                            love.graphics.setColor(100 + color, 250 - color, 0 )
                        else
                            love.graphics.setColor( cell.cost *3, 80, 0 )
                        end
                    end
                    if cell.pred then
                        love.graphics.setLineWidth(0.1)
                        love.graphics.line(cell.x, cell.y, cell.pred.x, cell.pred.y)
                    else
                        love.graphics.setPointSize(3)
                        love.graphics.points(cell.x, cell.y)
                    end

                end
            end
        end
    end

    love.graphics.setColor(200, 200, 0)
    drawGoal(goal)

    love.graphics.setPointSize(3)

    if path then
        for i, p in ipairs(path) do
            if p.motionPrimitive and HybridAStar.MotionPrimitives.isReverse(p.motionPrimitive) then
                love.graphics.setColor(0, 100, 255)
            else
                love.graphics.setColor( 255, 255, 255 )
            end
            if p.pred then
                love.graphics.setLineWidth(0.3)
                love.graphics.line(p.x, p.y, p.pred.x, p.pred.y)
            else
                love.graphics.points(p.x, p.y)
            end
        end
    end

    if dubinsPath then
        for i, p in ipairs(dubinsPath) do
            love.graphics.setColor(200, 200, 0)
            love.graphics.points(p.x, p.y)
        end
    end

    if pathFinder:isActive() then
        done, path = pathFinder:resume()
    end
end


local function love2real( x, y )
    return ( x / scale ) - xOffset,  - ( y / scale ) + yOffset
end

function love.mousepressed(x, y, button, istouch)
    if button == 1 then
        local x, y = love2real( x, y )
        local start = State3D(0, 0, 0 , 0)
        goal = State3D(x, y, goalHeading, 0)

        done, path = find(start, goal)

        if path then
            debug('Path found with %d nodes', #path)
        else
            debug('No path found')
        end
    end
    io.stdout:flush()
end

function love.keypressed(key, scancode, isrepeat)
    if key == 'left' then
        goalHeading = goalHeading + math.rad(15)
    elseif key == 'right' then
        goalHeading = goalHeading - math.rad(15)
    elseif key == '=' then
        scale = scale + 1
    elseif key == '-' then
        scale = scale - 1
    end
    xOffset, yOffset = width / scale / 2, height / scale / 2
    io.stdout:flush()
end
