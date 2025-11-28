--- @class Direction
--- @field dx 1|0|-1
--- @field dy 1|0|-1

--- @class Point3
--- @field x number
--- @field y number
--- @field z number

--- @class Navigator dead-reckoning based navigation
--- @field public x number the relative x offset from the beginning of navigation
--- @field public y number the relative y offset from the beginning of navigation
--- @field public z number the relative z offset from the beginning of navigation
--- @field protected dx number how the x changes when moving forward
--- @field protected dy number how the y changes when moving forward
--- @field public onUpdate fun(self: Navigator) is called on every update (movement or turning)
local Nav = {
    x = 0,
    y = 0,
    z = 0,
    dx = 0,
    dz = 1,
}

--- A no-op stub
function Nav:onUpdate() end

function Nav:moveForth()
    if turtle.forward() then
        self.x = self.x + self.dx
        self.z = self.z + self.dz
        self:onUpdate()
        return false
    end
end

function Nav:moveBack()
    if turtle.back() then
        self.x = self.x - self.dx
        self.z = self.z - self.dz
        self:onUpdate()
        return true
    end
    return false
end

function Nav:moveUp()
    if turtle.up() then
        self.y = self.y + 1
        self:onUpdate()
        return true
    end
    return false
end

function Nav:moveDown()
    if turtle.down() then
        self.y = self.y - 1
        self:onUpdate()
        return true
    end
    return false
end

--- Go forward some number or 1 steps
--- @param steps? number the number of steps to take forward (or back if negative)
--- @return boolean success whether the navigation was successful
function Nav:forth(steps)
    steps = steps or 1
    for _ = 1, math.abs(steps) do
        if steps > 0 then
            if not self:moveForth() then
                return false
            end
        elseif not self:moveBack() then
            return false
        end
    end
    return true
end

--- Go back some number or 1 steps
--- @param steps? number the number of steps to take back (or forward if negative)
--- @return boolean success whether the navigation was successful
function Nav:back(steps)
    return self:forth(-(steps or 1))
end

--- Go up some number or 1 steps
--- @param steps? number the number of steps to take up (or down if negative)
--- @return boolean success whether the navigation was successful
function Nav:up(steps)
    steps = steps or 1
    for _ = 1, math.abs(steps) do
        if steps > 0 then
            if not self:moveUp() then
                return false
            end
        elseif not self:moveDown() then
            return false
        end
    end
    return true
end

--- Go down some number or 1 steps
--- @param steps? number the number of steps to take down (or up if negative)
--- @return boolean success whether the navigation was successful
function Nav:down(steps)
    return self:up(-(steps or 1))
end

--- Turn left
--- @return boolean success
function Nav:turnLeft()
    if turtle.turnLeft() then
        self.dx, self.dz = -self.dz, self.dx
        self:onUpdate()
        return true
    end
    return false
end

--- Turn right
--- @return boolean success
function Nav:turnRight()
    if turtle.turnRight() then
        self.dx, self.dz = self.dz, -self.dx
        self:onUpdate()
        return true
    end
    return false
end

--- Turn around (so face backwards after)
--- @return boolean success
function Nav:turnAround()
    return self:turnLeft() and self:turnLeft()
end

--- Turn the navigator to face in such direction that forward motion will effect x and z coordinates accordingly
--- @param dx 1|0|-1 the resulting change in x direction after the turn
--- @param dz 1|0|-1 the resulting change in y direction after the turn
--- @return boolean success
--- @overload fun(self: Navigator, dir: Direction): boolean
function Nav:turnTo(dx, dz)
    if type(dx) == "table" then
        dz = dx.dz
        dx = dx.dx
    end
    assert(math.abs(dx) + math.abs(dz) == 1, "invalid direction")
    if dx ~= 0 then
        if self.dx == 0 then
            if self.dz == dx then
                return self:turnRight()
            else
                return self:turnLeft()
            end
        else
            return self.dx == dx or self:turnAround()
        end
    elseif self.dz == 0 then
        if self.dx == dz then
            return self:turnLeft()
        else
            return self:turnRight()
        end
    else
        return self.dz == dz or self:turnAround()
    end
end

--- Go to provided coordinates
--- @param x number the resulting x offset
--- @param y number the resulting y offset
--- @param z number the resulting z offset
--- @return boolean success
--- @overload fun(self: Navigator, point: Point3): boolean
function Nav:goTo(x, y, z)
    if type(x) == "table" then
        z = x.z
        y = x.y
        x = x.x
    end
    assert(x and y and z, "invalid coordinate")
    if self.y ~= y and not self:goUp(y - self.y) then
        return false
    end

    if self.x ~= x then
        if self.x > x then
            self:turnTo(-1, 0)
        else
            self:turnTo(1, 0)
        end
        if not self:forth(math.abs(x - self.x)) then
            return false
        end
    end

    if self.z ~= z then
        if self.z > z then
            self:turnTo(0, -1)
        else
            self:turnTo(0, 1)
        end
        if not self:forth(math.abs(z - self.z)) then
            return false
        end
    end
    return true
end

local NavMeta = {
    __index = Nav
}

--- Initialize a navigator instance
--- @param o? Navigator
--- @return Navigator
local function new(o)
    return setmetatable(o or {}, NavMeta)
end

return {
    new = new
}
