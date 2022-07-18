--[[
    GD50
    Breakout Remake

    -- PowerUp Class --

    Author: Rafael Alves
    Represents a power up that can be obtained in the game.
]]

PowerUp = Class{}

function PowerUp:init(skin)
    -- x positioned randomly in the screen
    -- 8 is half the width of the power up
    self.x = math.random(0, VIRTUAL_WIDTH - 8)

    -- y positioned outside the screen
    self.y = -16

    -- power up dimensions
    self.width = 16
    self.height = 16

    -- velocity in the y direction. Should move down the screen
    self.dy = POWER_UP_SPEED

    -- this will effectively be the power up that should be used
    self.skin = skin
end

--[[
    Expects an argument with a bounding box and 
    returns true if the bounding boxes of this and the argument overlap.
]]
function PowerUp:collides(target)
    -- first, check to see if the left edge of either is farther to the right
    -- than the right edge of the other
    if self.x > target.x + target.width or target.x > self.x + self.width then
        return false
    end

    -- then check to see if the bottom edge of either is higher than the top
    -- edge of the other
    if self.y > target.y + target.height or target.y > self.y + self.height then
        return false
    end 

    -- if the above aren't true, they're overlapping
    return true
end

function PowerUp:hit()
    -- play a sound effect
    gSounds['paddle-hit']:play()
end

function PowerUp:update(dt)
    -- move power up down the screen
    self.y = self.y + self.dy * dt
end

function PowerUp:render()
    -- gTexture is our global texture for all blocks
    -- gBallFrames is a table of quads mapping to each individual powerup skin in the texture
    love.graphics.draw(gTextures['main'], gFrames['powerups'][self.skin],
        self.x, self.y)
end