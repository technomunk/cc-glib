-- Run a calculation

local calc = require "calculator"

local expr = calc.parse({...})
local result = expr()

print(expr, '=', result)
