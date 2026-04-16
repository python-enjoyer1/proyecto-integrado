-- Yoooooooo. I implemented the vector class. If there's any shit you feel ain't right then change it.
vector = {x = 0, y = 0}

function vector:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end

function vector:normalize()
    local length = math.sqrt(self.x^2 + self.y^2)
    if length > 0 then
        self.x = self.x / length
        self.y = self.y / length
    end
end