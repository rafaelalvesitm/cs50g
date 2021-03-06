--[[
    GD50
    Legend of Zelda

    Author: Colton Ogden
    cogden@cs50.harvard.edu
]]

GAME_OBJECT_DEFS = {
    ['switch'] = {
        type = 'switch',
        texture = 'switches',
        frame = 2,
        width = 16,
        height = 16,
        solid = false,
        defaultState = 'unpressed',
        states = {
            ['unpressed'] = {
                frame = 2
            },
            ['pressed'] = {
                frame = 1
            }
        }
    },
    ['pot'] = {
        type = 'pot',
        texture = 'tiles',
        frame = 14, -- pot is the 14th tile in the tileset
        width = 16,
        height = 16,
        solid = true, 
        consumable = false, 
        defaultState = 'idle', -- pot is idle by default
        states = {
            ['idle'] = {
                frame = 14
            }
        }
    },
    ['heart'] = {
        type = 'heart',
        texture = 'hearts',
        frame = 5,
        width = 8,
        height = 8,
        scale = 0.6, 
        solid = false,
        consumable = true,
        defaultState = 'full',
        states = {
            ['full'] =  {
                frame = 5
            }
        }
    }
}