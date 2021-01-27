-- Calculator helper module

local metaNum = {
	__call = function(self)
		return self.val
	end,
	__tostring = function(self)
		return tostring(self.val)
	end,
}

local metaAdd = {
	__call = function(self)
		return self.lhs() + self.rhs()
	end,
	__tostring = function(self)
		return '('..tostring(self.lhs)..'+'..tostring(self.rhs)..')'
	end,
}

local metaSub = {
	__call = function(self)
		return self.lhs() - self.rhs()
	end,
	__tostring = function(self)
		return '('..tostring(self.lhs)..'-'..tostring(self.rhs)..')'
	end,
}

local metaMul = {
	__call = function(self)
		return self.lhs() * self.rhs()
	end,
	__tostring = function(self)
		return '('..tostring(self.lhs)..'*'..tostring(self.rhs)..')'
	end,
}

local metaDiv = {
	__call = function(self)
		return self.lhs() / self.rhs()
	end,
	__tostring = function(self)
		return '('..tostring(self.lhs)..'/'..tostring(self.rhs)..')'
	end,
}

-- Construct a new object representing a numerical value
local function newNum(val)
	return setmetatable({
		val = tonumber(val),
	}, metaNum)
end

-- Construct a new sum object
local function newAdd(lhs, rhs)
	return setmetatable({
		lhs = lhs,
		rhs = rhs,
	}, metaAdd)
end

-- Construct a new difference object
local function newSub(lhs, rhs)
	return setmetatable({
		lhs = lhs,
		rhs = rhs,
	}, metaSub)
end

-- Construct a new product object
local function newMul(lhs, rhs)
	return setmetatable({
		lhs = lhs,
		rhs = rhs,
	}, metaMul)
end

-- Construct a new division object
local function newDiv(lhs, rhs)
	return setmetatable({
		lhs = lhs,
		rhs = rhs,
	}, metaDiv)
end

-- Remove spaces on the left side of the string
local function pruneRight(str)
	local spaces = str:match("\s$")
	if spaces then
		return str:sub(1, #str - #spaces)
	end
	return str
end

-- Remove the first number in the provided string
local function popNumber(str)
	local exp = str:match("e%d*$")
	if exp then
		str = str:sub(1, #str - #exp)
	end
	local num = str:match("%d+%.?%d*$")
	assert(num, "expected a number, got \""..str..'\"')
	str = str:sub(1, #str-#num)
	if exp then
		num = num..exp
	end
	return tonumber(num), str
end

-- Process the first token in the provided string
local function popToken(str)
	local tokens = "()+-*x/"
	local char = str:sub(#str, #str)
	if char == '%' then
		char = '%%'
	end
	if tokens:find(char) then
		return char, str:sub(1, #str - 1)
	else
		return popNumber(str)
	end
end

-- Convert the provided string or array of strings into a stack of tokens
local function tokenize(arr)
	local result = {}
	if type(arr) == "string" then
		arr = { arr, }
	end

	for i = 1, #arr do
		local rest = arr[i]
		local token = nil
		while #rest > 0 do
			token, rest = popToken(pruneRight(rest))
			table.insert(result, token)
		end
	end
	return result
end

local parseExpr = nil

-- Parse a number of an expression surrounded by parenthesis 
local function parsePrimaryExpr(tokens)
	local t = table.remove(tokens)
	if t == '(' then
		local expr = parseExpr(tokens)
		assert(table.remove(tokens) == ')', "expected \")\"")
		return expr
	else
		assert(type(t) == "number", "expected a number")
		return newNum(t)
	end
end

-- Parse provided binary operations from the provided token stack
local function parseBinOpExpr(tokens, ops, parse)
	local expr = parse(tokens)
	while ops[tokens[#tokens]] do
		local t = table.remove(tokens)
		local rhs = parse(tokens)
		expr = ops[t](expr, rhs)
	end
	return expr
end

-- Parse multiplication or division expressions
local function parseMulOrDivExpr(tokens)
	local ops = {
		['*'] = newMul,
		['x'] = newMul,
		['/'] = newDiv,
	}
	return parseBinOpExpr(tokens, ops, parsePrimaryExpr)
end

-- Parse multiplication or division exprssions
local function parseAddOrSubExpr(tokens)
	local ops = {
		['+'] = newAdd,
		['-'] = newSub,
	}
	return parseBinOpExpr(tokens, ops, parseMulOrDivExpr)
end

parseExpr = parseAddOrSubExpr

-- Parse a token stack into an expression tree
local function parse(tokens)
	local expr = parseExpr(tokens)
	assert(#tokens == 0, "not all tokens were consumed!")
	return expr
end

return {
	tokenize = tokenize,
	parse = function(str) return parse(tokenize(str)) end,
	eval = function(str) return parse(tokenize(str))() end,
}
