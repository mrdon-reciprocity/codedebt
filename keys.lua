--
-- Created by IntelliJ IDEA.
-- User: mrdon
-- Date: 3/9/19
-- Time: 10:54 PM
-- To change this template use File | Settings | File Templates.
--

KEYS = {
    ["A"] = 1,
    ["B"] = 2,
    ["C"] = 3,
    ["D"] = 4,
    ["E"] = 5,
    ["F"] = 6,
    ["G"] = 7,
    ["H"] = 8,
    ["I"] = 9,
    ["J"] = 10,
    ["K"] = 11,
    ["L"] = 12,
    ["M"] = 13,
    ["N"] = 14,
    ["O"] = 15,
    ["P"] = 16,
    ["Q"] = 17,
    ["R"] = 18,
    ["S"] = 19,
    ["T"] = 20,
    ["U"] = 21,
    ["V"] = 22,
    ["W"] = 23,
    ["X"] = 24,
    ["Y"] = 25,
    ["Z"] = 26,
    ["0"] = 27,
    ["1"] = 28,
    ["2"] = 29,
    ["3"] = 30,
    ["4"] = 31,
    ["5"] = 32,
    ["6"] = 33,
    ["7"] = 34,
    ["8"] = 35,
    ["9"] = 36,
    ["-"] = 37,
    ["="] = 38,
    ["["] = 39,
    ["]"] = 40,
    ["\\"] = 41,
    [";"] = 42,
    ["'"] = 43,
    ["_"] = 44,
    [","] = 45,
    ["."] = 46,
    ["/"] = 47,
    [" "] = 48
}

KEYS_BY_CODE = {}
for k, v in pairs(KEYS) do
    KEYS_BY_CODE[v] = k
end