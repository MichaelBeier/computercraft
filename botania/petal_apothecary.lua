
local crafterPos = "top"

function main()
    while true do
        for i = 1, 16, 1 do
            local item = turtle.getItemDetail(i)
            if item ~= nil then
                craft()
                break
            end
        end
        os.sleep(1)
    end
end

function craft()
    local seedIndex = -1

    dropSpecificItem("minecraft:water_bucket")

    for i = 1, 16, 1 do
        local item = turtle.getItemDetail(i)
        if item ~= nil then
            if item["name"] ~= "minecraft:wheat_seeds" then
                turtle.select(i)
                turtle.dropDown()
            end
        end
    end

    dropSpecificItem("minecraft:wheat_seeds")

    pulseCrafter()

    pickUpEverything()
end

function pickUpEverything()
    while turtle.suckDown() == true do
        turtle.drop()
    end
end

function dropSpecificItem(itemName)
    for i = 1, 16, 1 do
        local item = turtle.getItemDetail(i)
        if item ~= nil then
            if item["name"] == itemName then
                turtle.select(i)
                turtle.dropDown()
                return
            end 
        end
    end
end

function pulseCrafter()
    redstone.setOutput(crafterPos, true)
    os.sleep(.5)
    redstone.setOutput(crafterPos, false)
end

main()