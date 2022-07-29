--[[
    GD50
    Legend of Zelda

    Author: Rafael Alves
]]

PlayerLiftPotState = Class{__includes = BaseState}

function PlayerLiftPotState:init(player, dungeon)
    self.player = player
    self.dungeon = dungeon

    -- lift-left, lift-up, etc
    self.player:changeAnimation('lift-' .. self.player.direction)
end

function PlayerLiftPotState:enter(params)

    -- restart sword swing sound for rapid swinging
    print("lift sound") 

    -- restart lift animation
    self.player.currentAnimation:refresh()
end

function PlayerLiftPotState:update(dt) 

    -- if we've fully elapsed through one cycle of animation, change back to idle state
    if self.player.currentAnimation.timesPlayed > 0 then
        self.player.currentAnimation.timesPlayed = 0
        self.player:changeState('idle')
    end

end

function PlayerLiftPotState:render()
    local anim = self.player.currentAnimation
    love.graphics.draw(gTextures[anim.texture], gFrames[anim.texture][anim:getCurrentFrame()],
        math.floor(self.player.x - self.player.offsetX), math.floor(self.player.y - self.player.offsetY))
end