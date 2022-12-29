local maxAge = 6

main()

function main() 
    while true do 
        local blockDetail = turtle.inspect()
        digConditionally(blockDetail)
    end
end

function digConditionally(blockDetail)
    if blockDetail ~= nil then
        if blockDetail["state"]["age"] == maxAge then
            turtle.dig()
        end
    end
end

function digDownConditionally(blockDetail)
    if blockDetail ~= nil then
        if blockDetail["state"]["age"] == maxAge then
            turtle.digDown()
        end
    end
end
