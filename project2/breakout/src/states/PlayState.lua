--[[
    GD50
    Breakout Remake

    -- PlayState Class --

    Author: Colton Ogden
    cogden@cs50.harvard.edu

    Represents the state of the game in which we are actively playing;
    player should control the paddle, with the ball actively bouncing between
    the bricks, walls, and the paddle. If the ball goes below the paddle, then
    the player should lose one point of health and be taken either to the Game
    Over screen if at 0 health or the Serve screen otherwise.
]]

local POINTS_TO_GROW_PADDLE = 300

PlayState = Class{__includes = BaseState}

--[[
    We initialize what's in our PlayState via a state table that we pass between
    states as we go from playing to serving.
]]
function PlayState:enter(params)
    self.paddle = params.paddle
    self.bricks = params.bricks
    self.health = params.health
    self.score = params.score
    self.highScores = params.highScores
    -- Initialize a table to store each ball
    self.balls = {}
    self.level = params.level
    self.powerups = {}
    self.timer = 0
    self.recoverPoints = 5000
    self.increase_paddle = self.score + POINTS_TO_GROW_PADDLE
    
    -- flag to check if there is a blocked brick
    self.blocked_level = false
    for k, brick in pairs(self.bricks) do
        if brick.locked == true then
            self.blocked_level = true
        end
    end

    -- initially there is no key to open the locked brick
    self.key = false

    -- give a ball a random starting velocity
    params.ball.dx = math.random(-200, 200)
    params.ball.dy = math.random(-50, -60)

    -- Add a ball to the table
    table.insert(self.balls, params.ball)
end

function PlayState:update(dt)
    if self.paused then
        if love.keyboard.wasPressed('space') then
            self.paused = false
            gSounds['pause']:play()
        else
            return
        end
    elseif love.keyboard.wasPressed('space') then
        self.paused = true
        gSounds['pause']:play()
        return
    end

    -- update positions based on velocity
    self.paddle:update(dt)

    for k, ball in pairs(self.balls) do
        ball:update(dt)

        if ball:collides(self.paddle) then
            -- raise ball above paddle in case it goes below it, then reverse dy
            ball.y = self.paddle.y - 8
            ball.dy = -ball.dy

            --
            -- tweak angle of bounce based on where it hits the paddle
            --

            -- if we hit the paddle on its left side while moving left...
            if ball.x < self.paddle.x + (self.paddle.width / 2) and self.paddle.dx < 0 then
                ball.dx = -50 + -(8 * (self.paddle.x + self.paddle.width / 2 - ball.x))
            
            -- else if we hit the paddle on its right side while moving right...
            elseif ball.x > self.paddle.x + (self.paddle.width / 2) and self.paddle.dx > 0 then
                ball.dx = 50 + (8 * math.abs(self.paddle.x + self.paddle.width / 2 - ball.x))
            end

            gSounds['paddle-hit']:play()
        end
    end

    -- detect collision across all bricks with the ball
    for k, brick in pairs(self.bricks) do
        for j, ball in pairs(self.balls) do
            -- only check collision if we're in play
            if brick.inPlay and ball:collides(brick) then
                if brick.locked and self.key then
                    -- add to score
                    self.score = self.score + 2000
                    -- trigger the brick's hit function, which removes it from play
                    brick:unlock()
                elseif brick.locked == false then
                    -- add to score
                    self.score = self.score + (brick.tier * 200 + brick.color * 25)

                    -- trigger the brick's hit function, which removes it from play
                    brick:hit()
                end

                -- if we have enough points, recover a point of health
                if self.score > self.recoverPoints then
                    -- can't go above 3 health
                    self.health = math.min(3, self.health + 1)

                    -- multiply recover points by 2
                    self.recoverPoints = self.recoverPoints + math.min(100000, self.recoverPoints * 2)

                    -- play recover sound effect
                    gSounds['recover']:play()
                end

                -- go to our victory screen if there are no more bricks left
                if self:checkVictory() then
                    gSounds['victory']:play()

                    gStateMachine:change('victory', {
                        level = self.level,
                        paddle = self.paddle,
                        health = self.health,
                        score = self.score,
                        highScores = self.highScores,
                        ball = ball,
                        recoverPoints = self.recoverPoints
                    })
                end

                --
                -- collision code for bricks
                --
                -- we check to see if the opposite side of our velocity is outside of the brick;
                -- if it is, we trigger a collision on that side. else we're within the X + width of
                -- the brick and should check to see if the top or bottom edge is outside of the brick,
                -- colliding on the top or bottom accordingly 
                --

                -- left edge; only check if we're moving right, and offset the check by a couple of pixels
                -- so that flush corner hits register as Y flips, not X flips
                if ball.x + 2 < brick.x and ball.dx > 0 then
                    
                    -- flip x velocity and reset position outside of brick
                    ball.dx = -ball.dx
                    ball.x = brick.x - 8
                
                -- right edge; only check if we're moving left, , and offset the check by a couple of pixels
                -- so that flush corner hits register as Y flips, not X flips
                elseif ball.x + 6 > brick.x + brick.width and ball.dx < 0 then
                    
                    -- flip x velocity and reset position outside of brick
                    ball.dx = -ball.dx
                    ball.x = brick.x + 32
                
                -- top edge if no X collisions, always check
                elseif ball.y < brick.y then
                    
                    -- flip y velocity and reset position outside of brick
                    ball.dy = -ball.dy
                    ball.y = brick.y - 8
                
                -- bottom edge if no X collisions or top collision, last possibility
                else
                    
                    -- flip y velocity and reset position outside of brick
                    ball.dy = -ball.dy
                    ball.y = brick.y + 16
                end

                -- slightly scale the y velocity to speed up the game, capping at +- 150
                if math.abs(ball.dy) < 150 then
                    ball.dy = ball.dy * 1.02
                end

                -- only allow colliding with one brick, for corners
                break
            end
        end
    end


    -- if ball goes below bounds, revert to serve state and decrease health
    for k, ball in pairs(self.balls) do
        if ball.y >= VIRTUAL_HEIGHT then
            -- remove the ball from the table
            table.remove(self.balls, k)
            -- if we've lost all our balls, remove one health point
            if #self.balls == 0 then
                self.health = self.health - 1
                gSounds['hurt']:play()
                
                -- shrinks the paddle when losing a life
                self.paddle:shrink()

                if self.health == 0 then
                    gStateMachine:change('game-over', {
                        score = self.score,
                        highScores = self.highScores
                    })
                else
                    gStateMachine:change('serve', {
                        paddle = self.paddle,
                        bricks = self.bricks,
                        health = self.health,
                        score = self.score,
                        highScores = self.highScores,
                        level = self.level,
                        recoverPoints = self.recoverPoints
                    })
                end
            end
        end
    end


    -- for rendering particle systems
    for k, brick in pairs(self.bricks) do
        brick:update(dt)
    end

    if love.keyboard.wasPressed('escape') then
        love.event.quit()
    end

    -- update timer
    self.timer = self.timer + dt

    -- Spawn a power up every 10 seconds
    if self.timer > POWERUP_SPAWN_INTERVAL then
        -- set the timer back to 0
        self.timer = 0

        -- if the level has a locked brick, spawn a random power up
        local x = math.random(2)
        if self.blocked_level == true and x == 1 then
            table.insert(self.powerups, PowerUp(10))
        else
            -- Add a power up to generate two balls
            table.insert(self.powerups, PowerUp(2))
        end

        -- Change PowerUp spawn interval 
        POWERUP_SPAWN_INTERVAL = math.random(10, 20)
    end

    -- update all power ups to move
    for k, powerup in pairs(self.powerups) do
        powerup:update(dt)
    end

    -- Remove the power up if it touches the paddle or the bottom of the screen
    for k, powerup in pairs(self.powerups) do
        if powerup:collides(self.paddle) then
            if powerup.skin == 10 then
                -- skin 10 means the key power up
                self.blocked_level = false
                powerup:hit()
                self.key = true
            else
                -- other skin means the two ball power up
                powerup:hit()
                ball_1 = Ball()
                ball_1.skin = math.random(7)
                ball_1.x = VIRTUAL_WIDTH / 2 - 8
                ball_1.y = self.paddle.y - 8
                ball_1.dx = math.random(-200, 200)
                ball_1.dy = math.random(-50, -60)
                ball_2 = Ball()
                ball_2.skin = math.random(7)
                ball_2.x = VIRTUAL_WIDTH / 2 - 8
                ball_2.y = self.paddle.y - 8
                ball_2.dx = math.random(-200, 200)
                ball_2.dy =math.random(-50, -60)
                table.insert(self.balls, ball_1)
                table.insert(self.balls, ball_2)
            end
            -- remove the power up from the table
            table.remove(self.powerups, k)
        elseif powerup.y > VIRTUAL_HEIGHT then
            table.remove(self.powerups, k)
        end
    end

    -- If the current score is high enought, grow the paddle
    if self.score > self.increase_paddle then
        -- Grow the paddle
        self.paddle:grow()
        -- update the amount of points needed to increase the paddle
        self.increase_paddle = self.increase_paddle + POINTS_TO_GROW_PADDLE
    end

end

function PlayState:render()
    -- render bricks
    for k, brick in pairs(self.bricks) do
        brick:render()
    end

    -- render all particle systems
    for k, brick in pairs(self.bricks) do
        brick:renderParticles()
    end
    
    self.paddle:render()

    -- render all balls
    for k, ball in pairs(self.balls) do
        ball:render()
    end
    
    -- render power ups
    for k, powerup in pairs(self.powerups) do
        powerup:render()
    end

    renderScore(self.score)
    renderHealth(self.health)

    -- pause text, if paused
    if self.paused then
        love.graphics.setFont(gFonts['large'])
        love.graphics.printf("PAUSED", 0, VIRTUAL_HEIGHT / 2 - 16, VIRTUAL_WIDTH, 'center')
    end
end

function PlayState:checkVictory()
    for k, brick in pairs(self.bricks) do
        if brick.inPlay then
            return false
        end 
    end

    return true
end