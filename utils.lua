local Main = {}

-- Yoooooooo. I implemented the vector class. If there's any shit you feel ain't right then change it.
--R I approve of this.

Main.Timer = {Stored_Times = {}} --R basically a wait() then does a callback
Main.Vector = {x = 0, y = 0}

function Main.Vector:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end

function Main.Vector:normalize()
    local length = math.sqrt(self.x^2 + self.y^2)
    if length > 0 then
        self.x = self.x / length
        self.y = self.y / length
    end
end

--R Timer Functions. Only use if it's for delayed triggers, else use coroutines.

function Main.Timer:new(Duration, OnComplete) --R Set amount of time u want to wait then runs code.
    table.insert(Main.Timer.Stored_Times, {Time = Duration, Callback = OnComplete})
end

-- Good shit, but remember to only capitalize if making a class, not a variable.
--R Got it.
function Main.Timer:Update(dt) --R just put this into love.update()
    for i=#Main.Timer.Stored_Times, 1,-1 do --R this prevents other indexes to fill in gaps after deletion.
        local stored = Main.Timer.Stored_Times[i]
        stored.Time = stored.Time - dt
        if stored.Time <= 0 then
            stored.Callback()
            table.remove(Main.Timer.Stored_Times, i)
        end
    end
end

return Main