
GameOverState = {
    high_score_char_pos = KEYS["_"],
    high_score_name = "",
    p = Nil
}


function GameOverState:start()
    self.menu_cursor = 1
    self.high_score_char_pos = KEYS["_"]
    self.high_score_name = ""
    self.p = ChasingState.p
end

function GameOverState:draw()
    cls()
    for x = 1, 14, 2 do
        rectb(2 + x, 1 + x, 240 - 4 - x, 136 - 2 - x, x)
    end

    local offset = 40
    local text_color = TEXT_TYPED
    local text_ = "Success"
    if self.p.score <= 600 then
        text_color = TEXT_BAD
        text_ = "No release"
    end
    print(text_, 30, 30, text_color, false, 3)
    print("Your score: " .. self.p.score, 30, 50, TEXT_TYPED, false, 1)
    print("Enter Your name: " .. self.p.name, 30, 80, TEXT_TYPED, true, 1)
    print(KEYS_BY_CODE[self.high_score_char_pos], 30 + (17 * 6) + string.len(self.p.name) * 6, 80, TEXT_UNTYPED, true, 1)
end

function GameOverState:input()

    if btnp(0, 10, 10) then
        self.high_score_char_pos = self.high_score_char_pos + 1
        if self.high_score_char_pos > 48 then
            self.high_score_char_pos = 1
        end
    elseif btnp(1, 10, 10) then
        self.high_score_char_pos = self.high_score_char_pos - 1
        if self.high_score_char_pos < 1 then
            self.high_score_char_pos = 48
        end
    elseif btnp(4) or keyp(50) then
        self.p.name = self.p.name .. KEYS_BY_CODE[self.high_score_char_pos]
    else
        for k, v in pairs(KEYS) do
            if keyp(v) then
                self.p.name = self.p.name .. k
            end
        end
    end

    if #self.p.name == 3 then
        self.high_score_char_pos = KEYS[" "]
        HighScoresState:add_score(self.p.name, self.p.score)
        new_state(HighScoresState)
    end
end
