function normalize(x, y)
    local length = math.sqrt(x^2 + y^2)
    if length > 0 then
        return {x = x/length, y = y/length}
    end
    return {x = 0, y = 0}
end

vector = {}