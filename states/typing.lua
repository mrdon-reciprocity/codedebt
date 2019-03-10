
TypingState = {
    treasure = Nil,
    p=Nil
}

function TypingState:start()
    self.treasure = ChasingState.current_treasure
    self.p = ChasingState.p
end

function TypingState:input()
    local current_letter = string.upper(self.treasure.word:sub(self.treasure.current_pos, self.treasure.current_pos))

    if keyp(KEYS[current_letter]) == true then
        self.treasure.current_pos = self.treasure.current_pos + 1
        self.treasure.current_char_code = KEYS["_"]
    elseif btnp(0, 10, 10) then
        self.treasure.current_char_code = self.treasure.current_char_code + 1
        if self.treasure.current_char_code > 48 then
            self.treasure.current_char_code = 1
        end
    elseif btnp(1, 10, 10) then
        self.treasure.current_char_code = self.treasure.current_char_code - 1
        if self.treasure.current_char_code < 1 then
            self.treasure.current_char_code = 48
        end
    end
    if KEYS_BY_CODE[self.treasure.current_char_code] == current_letter then
        self.treasure.current_pos = self.treasure.current_pos + 1
        self.treasure.current_char_code = KEYS["_"]
    end
    if self.treasure.current_pos == string.len(self.treasure.word) + 1 then
        self.treasure.consumed = true
        self.p.x = self.treasure.x
        self.p.y = self.treasure.y
        local rand_plus = math.random(-5, 5)
        self.p.score = self.p.score + self.treasure.score + rand_plus
        self.treasure = nil
        pop_state()
        music(1, 0, -1, false)
    end
end

function TypingState:draw()
    --Draw rectangle
    rect(8, 8, 204, 104, 1)
    rect(10, 10, 200, 100, 0)

    print(self.treasure.word, 15, 15, TEXT_UNTYPED, true, 2)

    local typed_length = 0
    if self.treasure.current_pos ~= 1 then
        local typed_text = self.treasure.word:sub(1, self.treasure.current_pos - 1)

        print(typed_text, 15, 35, TEXT_TYPED, true, 2)
        typed_length = string.len(typed_text)
    end

    print(KEYS_BY_CODE[self.treasure.current_char_code], 15 + typed_length * 12, 35, TEXT_UNTYPED, true, 2)
end


