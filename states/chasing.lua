
ChasingState = {
    treasures = {},
    treasure_words = {
        "ServiceNow",
        "Blocker",
        "Reccurrence",
        "Fix bug",
        "Coffee",
        "Meeting",
        "Another meeting",
        "Vulnerability",
        "GitHub is down",
        "Audit Wizard",
        "Fix bug"
    },
    p = {
        x = 1,
        y = 1
    },
    start_time = Nil,
    bad_guys = {},
    current_treasure = Nil,
    exit_door = {
        x = 28,
        y = 3,
        tile = EXIT
    }
}

function ChasingState:start()
    --player object
    self.p = {
        x = 3, --center of screen x
        y = 1,
        score = 0,
        name = ""
    } --center of screen y

    for x = 1, 15, 1 do
        local tx = 0
        local ty = 0
        while tx == 0 do
            tx = math.random(SCREEN_X)
            ty = math.random(SCREEN_Y)
            if mget(tx, ty) ~= FLOOR or (tx == self.p.x and ty == self.p.y) then
                tx = 0
            else
                for x = 1, #self.treasures, 1 do
                    local t = self.treasures[x]
                    if t.x == tx and t.y == ty then
                        tx = 0
                    end
                end
            end
        end
        self.treasures[x] = {
            x = tx,
            y = ty,
            word = self.treasure_words[math.random(#self.treasure_words)],
            current_pos = 1,
            current_char_code = KEYS["_"],
            score = 100,
            tile = TREASURE,
            consumed = false
        }
    end

    self.start_time = time()
    self:_generate_bad_guys()
end

function ChasingState:_generate_bad_guys()
    for x = 1, 5, 1 do
        local bx = 0
        local by = 0
        while bx == 0 do
            bx = math.random(SCREEN_X)
            by = math.random(SCREEN_Y)
            if mget(bx, by) ~= FLOOR then
                bx = 0
            end
            for pos = 1, #self.treasures, 1 do
                local treasure = self.treasures[pos]
                if treasure.x == bx and treasure.y == by then
                    bx = 0
                end
            end
        end
        self.bad_guys[x] = {
            x = bx,
            y = by,
            score = 70,
            tile = BAD_GUY,
            consumed = false
        }
    end
end

--player movement
--we'll use the btnp() function to detect a single button press
function ChasingState:input()
    local x = self.p.x
    local y = self.p.y
    --player presses "up"
    if btnp(0, MOVEMENT_DELAY, MOVEMENT_SPEED) then
        y = self.p.y - 1
        music(3, 0, -1, false)
    end
    --player presses "down"
    if btnp(1, MOVEMENT_DELAY, MOVEMENT_SPEED) then
        y = self.p.y + 1
        music(3, 0, -1, false)
    end
    --player presses "left"
    if btnp(2, MOVEMENT_DELAY, MOVEMENT_SPEED) then
        x = self.p.x - 1
        music(3, 0, -1, false)
    end
    --player presses "right"
    if btnp(3, MOVEMENT_DELAY, MOVEMENT_SPEED) then
        x = self.p.x + 1
        music(3, 0, -1, false)
    end
    local next_tile = mget(x, y)

    local found = false
    for pos = 1, #self.treasures, 1 do
        local treasure = self.treasures[pos]
        if treasure.x == x and treasure.y == y and treasure.consumed == false then
            self.current_treasure = treasure
            new_state(TypingState)
            music(0, 0, -1, false)
            found = true
        end
    end

    for pos = 1, #self.bad_guys, 1 do
        local bad_guy = self.bad_guys[pos]
        if bad_guy.x == x and bad_guy.y == y and bad_guy.consumed == false then
            music(0, 0, -1, false)
            bad_guy.consumed = true
            self.p.score = self.p.score - bad_guy.score
            found = true
        end
    end

    if found == false then
        if self.exit_door.x == x and self.exit_door.y == y then
            self:game_over()
            music(2, 0, -1, true)
            self.p.score = self.p.score + 500
        elseif next_tile == FLOOR then
            self.p.x = x
            self.p.y = y
        end
    end
end

function ChasingState:game_over()
    self.start_time = Nil
    new_state(GameOverState)
end

function ChasingState:game_over_timeout()
    self.p.score = 0
    self:game_over()
end

--draw screen graphics
function ChasingState:draw()
    cls()
    map(0, 0, SCREEN_X + 1, SCREEN_Y + 1)

    --multiplying the player coors by 8 (the size of the map cells)
    --gives us grid movement
    spr(DUDE, self.p.x * 8, self.p.y * 8, 8)

    for pos = 1, #self.treasures, 1 do
        local treasure = self.treasures[pos]
        if treasure.consumed == false then
            spr(treasure.tile, treasure.x * 8, treasure.y * 8, 8)
        end
    end

    local time_left = self:_get_time_left()
    if time_left <= GAME_LENGTH - 5 then
        for pos = 1, #self.bad_guys, 1 do
            local bad_guy = self.bad_guys[pos]
            if bad_guy.consumed == false then
                local bad_guy = self.bad_guys[pos]
                spr(bad_guy.tile, bad_guy.x * 8, bad_guy.y * 8, 8)
            end
        end
    end
end

function ChasingState:_get_time_left()
    local secs_in_game = math.floor((time() - self.start_time) / 1000)
    local time_left = 0
    if secs_in_game < GAME_LENGTH then
        time_left = GAME_LENGTH - secs_in_game
    end
    return time_left
end

function ChasingState:draw_status()
    local time_left = self:_get_time_left()
    local timer_color = SCORE_LINE
    if time_left < 10 then
        timer_color = SCORE_TIMELOW
    end

    if time_left == 0 then
        self:game_over_timeout()
    end

    print("Time left: " .. time_left, 10, WINDOW_Y - 10, timer_color, false, 1)
    print("Score: " .. self.p.score, WINDOW_X / 2, WINDOW_Y - 10, SCORE_LINE, false, 1)
end
