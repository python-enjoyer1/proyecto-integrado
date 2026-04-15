function normalize(x, y)
    local length = math.sqrt(x^2 + y^2)
    if length > 0 then
        return x/length, y/length
    end
end