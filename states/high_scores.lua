
HighScoresState = {
    scores = {
        {
            name = "AAA",
            score = 500
        }, {
            name = "BBB",
            score = 200
        }
    }
}

function HighScoresState:start()
end

function HighScoresState:draw()
    --Draw rectangle
    rect(15, 15, WINDOW_X - 30, WINDOW_Y - 30, 0)

    print("High Scores", 25, 17, TEXT_TYPED, true, 2)

    for x = 1, #self.scores, 1 do
        print(self.scores[x].name .. " -- " .. self.scores[x].score, 30, 20 + 15 * x, TEXT_UNTYPED)
    end

    print("Return to Menu", 25, 120, TEXT_TYPED, true, 1.5)
end

function HighScoresState:input()
    if keyp(48) or keyp(50) or btnp(4) then
        new_state(MainMenuState)
    end
end

function HighScoresState:add_score(name, score_value)

    local score = {
        name=name,
        score=score_value
    }
    local added = false
    for pos = 1, #self.scores, 1 do
        if added == false and score.score >= self.scores[pos].score then
            table.insert(self.scores, pos, score)
            added = true
        end
    end
    if added == false then
        self.scores[#self.scores + 1] = score
    end

    if #self.scores > 6 then
        table.remove(self.scores)
    end
end

