local title = 'DeluxeSchlange'

local cellSize = 20
local xCells = 25
local yCells = 25
local width = xCells * cellSize
local height = yCells * cellSize

local up, down, left, right = 1, 2, 3, 4
local speed = 1
local defaultTick = 0.15
local speedyTick = 0.12

local colors = {
    apple = {1, 0.03, 0, 1},
    wall = {0.6, 0.6, 0.6, 1},
    snake = {0.25, 0.63, 0.29},
    speedy = {0, 1, 1},
    ground = {0.25, 0.25, 0.25, 1}
}

local reset = 5
local appleReset = 5
local appleBlink = 4
local wall = {}

math.randomseed(os.time())

love.filesystem.setIdentity(title)
love.window.setTitle(title)
love.window.setMode(width, height)

for i = 1, 5 do
    table.insert(wall, {x = i, y = 1})
    table.insert(wall, {x = i, y = yCells})
    table.insert(wall, {x = (xCells + 1) - i, y = 1})
    table.insert(wall, {x = (xCells + 1) - i, y = yCells})
    table.insert(wall, {x = 1, y = i})
    table.insert(wall, {x = xCells, y = i})
    table.insert(wall, {x = 1, y = (yCells + 1) - i})
    table.insert(wall, {x = xCells, y = (yCells + 1) - i})
end

function love.load()
    loadVars()    
    loadCanvas()
end

function loadVars()
    snake = {
        {x = 7, y = 13},
        {x = 6, y = 13},
        {x = 5, y = 13}
    }
    apple = {x = 20, y = 13}
    moves = {}
    alive = true
    blink = false
    speedy = false
    tick = defaultTick
    score = 0
    timer = 0
    appleTimer = 0
end

function loadCanvas()
    canvas = love.graphics.newCanvas()
    love.graphics.setCanvas(canvas)
        love.graphics.clear()
        love.graphics.setBlendMode('alpha')
        love.graphics.setColor(colors.ground)
        love.graphics.rectangle('fill', 0, 0, width, height)
        love.graphics.setColor(colors.wall)
        for _, pos in ipairs(wall) do drawCell(pos.x, pos.y, true) end
    love.graphics.setCanvas()
end

function love.keyreleased(key)
    if isMoveKey(key) then handleMoveKey(key) else handleCmdKey(key) end
end

function isMoveKey(key)
    return key == 'up' or key == 'down' or key == 'left' or key == 'right'
end

function handleMoveKey(key)
    local dir = moves[#moves]
    if (key == 'up' and dir ~= up and dir ~= down) then table.insert(moves, up)
    elseif (key == 'right' and dir ~= right and dir ~= left) then table.insert(moves, right)
    elseif (key == 'down' and dir ~= down and dir ~= up) then table.insert(moves, down)
    elseif (key == 'left' and dir ~= left and dir ~= right and dir ~= nil) then table.insert(moves, left)
    end
end

function handleCmdKey(key)
    if key == 'escape' then love.event.quit()
    elseif key == 'c' then love.graphics.captureScreenshot(title .. '_' .. os.time() .. '.png')
    end 
end

function love.update(dt)
    if #moves == 0 then 
        return
    end

    timer = timer + dt

    if alive then
        appleTimer = appleTimer + dt

        if timer >= tick then
            timer = timer - tick

            if appleTimer >= appleBlink then
                blink = not blink
            end

            if #moves > 1 then 
                table.remove(moves, 1)
            end

            local x, y = snake[1].x, snake[1].y
            local dir = moves[1]

            if dir == right then 
                x = x + speed
                if x > xCells then 
                    x = 1
                end
            elseif dir == up then
                y = y - speed
                if y < 1 then
                    y = yCells
                end
            elseif dir == left then
                x = x - speed
                if x < 1 then
                    x = xCells
                end
            elseif dir == down then
                y = y + speed
                if y > yCells then
                    y = 1
                end
            end

            if gameOver(x, y) then
                alive = false
                return
            end
            
            local scored = false
            if x == apple.x and y == apple.y then
                score = score + 1
                scored = true
                if not speedy and score > 5 and rng() then
                    speedy = true
                    tick = speedyTick
                else
                    speedy = false
                    tick = defaultTick
                end
            end
            
            table.insert(snake, 1, {x = x, y = y})
            if scored then
                updateApple()
            else
                table.remove(snake)
            end
        end

        if appleTimer >= appleReset then
            appleTimer = appleTimer - appleReset
            updateApple()
        end
    else
        if timer >= reset then
            loadVars()
        end
    end
    
end

function gameOver(x, y)
    return selfCrash(x, y) or wallCrash(x, y)
end

function selfCrash(x, y)
    for i = 2, #snake - 1 do
        if x == snake[i].x and y == snake[i].y then
            return true
        end
    end
    return false
end

function wallCrash(x, y)
    for _, pos in ipairs(wall) do
        if pos.x == x and pos.y == y then
            return true 
        end
    end
    return false
end

function updateApple()
    local available = {}
    for x = 2, xCells - 1 do
        for y = 2, yCells - 1 do
            local empty = true
            if empty then
                for _, pos in ipairs(snake) do
                    if pos.x == x and pos.y == y then
                        empty = false
                    end
                end
            end
            if empty then
                table.insert(available, {x = x, y = y})
            end
        end
    end
    apple = available[math.random(#available)]
    blink = false
    appleTimer = 0
end

function rng()
    return math.random(10) % 10 == 0
end

function love.draw()
    drawCanvas()
    drawSnake()
    drawApple()
    drawScore()
end

function drawCanvas()
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(canvas)
end

function drawSnake()
    local color = colors.snake
    if speedy then
        color = colors.speedy
    end
    love.graphics.setColor(color)
    for i, pos in ipairs(snake) do drawCell(pos.x, pos.y) end
end

function drawApple()
    if blink then return end
    local color = colors.apple
    if speedy then
        color = colors.speedy
    end
    love.graphics.setColor(color)
    drawCell(apple.x, apple.y)
end

function drawScore()
    love.graphics.setColor(1, 1, 1, 1)
    if alive then
        love.graphics.print('SCORE ' .. score, 5, 2)
    else
        love.graphics.printf('YOU DONE GOOFED', 0, (height / 2) - 10, width, 'center')
        love.graphics.printf('FINAL SCORE ' .. score, 0, (height / 2) + 10, width, 'center')
    end
end

function drawCell(x, y, fill)
    local margin = 1
    if fill then margin = 0 end
    love.graphics.rectangle(
        'fill',
        (x - 1) * cellSize,
        (y - 1) * cellSize,
        cellSize - margin,
        cellSize - margin
    )
end

