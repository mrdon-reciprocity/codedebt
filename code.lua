-- title:  simple collision detection
-- author: Bear Thorne
-- desc:   Detecting Collision for Grid Movement
-- script: lua


require "keys"
require "states/main_menu"
require "states/high_scores"
require "states/game_over"
require "states/chasing"
require "states/typing"

--sprite vars
FLOOR = 1 --the floor sprite will be stored in the 1 slot
WALL = 224 --the wall sprite will be stored in the 17 slot
DUDE = 16 --the player sprite will be stored in the 33 slot
TREASURE = 194 -- the treasure sprite will be stored in the __ slot
EXIT = 196 -- exit door end game
BAD_GUY = 96

--game constants
SCREEN_X = 29
SCREEN_Y = 16
WINDOW_X = 240
WINDOW_Y = 136
MOVEMENT_SPEED = 10
MOVEMENT_DELAY = 0

--colors
TEXT_TYPED = 8
TEXT_UNTYPED = 13
TEXT_BAD = 9
SCORE_LINE = 2
SCORE_TIMELOW = 6

GAME_LENGTH = 45


state = MainMenuState
last_state = MainMenuState


function new_state(s)
    last_state = state
    state = s
    state:start()
end

function pop_state()
    state = last_state
end

new_state(MainMenuState)
function TIC()
    state:input()
    state:draw()
end

function OVR()
    if state == TypingState or state == ChasingState then
        ChasingState:draw_status()
    end
end
