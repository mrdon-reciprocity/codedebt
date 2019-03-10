
MainMenuState = {
    cursor = 1,
    menu_cursor = 1,
    options = { "Play", "High Scores", "Quit" },
}

function MainMenuState:start()
    self.cursor = 1
    self.menu_cursor = 1
end

function MainMenuState:draw()
    cls()
    local offset = math.floor(time() / 1000) % 5

    for x = 1, 5, 1 do
        local color = x + offset
        if color > 7 then
            color = color - 7
        end
        local xoffset =
        rectb(2 + (2 * x), 1 + (2 * x), WINDOW_X - (2 * x) - 4, WINDOW_Y - (2 * x) - 2, color)
    end

    local offset = 25
    print("Release chasing", 30, 30, TEXT_TYPED, false, 2)
    for k, v in pairs(self.options) do
        if k == self.cursor then
            print(v, 50, offset * k + 30, TEXT_TYPED, false, 2)
        else
            print(v, 50, offset * k + 30, TEXT_UNTYPED, false, 1.5)
        end
    end
end

function MainMenuState:input()
    if btnp(0) then
        self.cursor = self.cursor - 1
        if self.cursor < 1 then
            self.cursor = #self.options
        end
    elseif btnp(1) then
        self.cursor = self.cursor + 1
        if self.cursor > #self.options then
            self.cursor = 1
        end
    elseif btnp(4) or keyp(50) then
        if self.cursor == 1 then
            new_state(ChasingState)
        elseif self.cursor == 2 then
            new_state(HighScoresState)
        elseif self.cursor == 3 then
            exit()
        end
    end
end

