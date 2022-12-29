-- all sendRednet: with timeout + retries!

local modemSide = "left"
local schedulerHostname = "quarry.scheduler1"


local strip = {}
local unload_slot = 15
local fuel_slot = 16
local schedulerID = 0
local maxDepth = -56

-- N, E, S, W
--  0,  1,  2,  3
local direction = nil


function header()
    print("---------------------------------------")
    print("    Basti's awesome quarry program!    ")
    print("             Worker Turtle             ")
    print("---------------------------------------")
end

function setup()
    strip = {}

    rednet.open(modemSide)

    schedulerID = rednet.lookup(schedulerHostname, schedulerHostname)

    turtle.select(1)
    turtle.transferTo(unload_slot)

    turtle.select(2)
    turtle.transferTo(fuel_slot)

    turtle.select(1)
end

function goToMovementChannel(movementChannel)
    local posX, posY, posZ = gps.locate()

    while (posY ~= movementChannel) do
        if (posY > movementChannel) then
            local s = turtle.down()
            if (not s) then
                for i = 1, 5, 1 do
                    if (turtle.detectDown()) then
                        sleep(.5)
                    end
                end
                if (turtle.detectDown()) then
                    turtle.digDown()
                end
            end
        else 
            local s = turtle.up()
            if (not s) then
                for i = 1, 5, 1 do
                    if (turtle.detectUp()) then
                        sleep(.5)
                    end
                end
                if (turtle.detectUp()) then
                    turtle.digUp()
                end
            end
            
        end
        posX, posY, posZ = gps.locate()
    end
end

function goToFloor()
    local counter = 5

    while(counter > 0) do
        while (not turtle.detectDown()) do
            turtle.down()
        end
        sleep(1)
        counter = counter -1
    end
end

function navigateTo(x, z)
    local posX, posY, posZ = gps.locate()

    print(posX)
    print(x)
    if (posX ~= x or posZ ~= z) then
        while (posX ~= x) do
            if (posX < x) then
                -- move east
                turnDirection(1)
                turtle.forward()
            else 
                -- move west
                turnDirection(3)
                turtle.forward()
            end
            posX, posY, posZ = gps.locate()
        end

        while (posZ ~= z) do
            if (posZ < z) then
                -- move south
                turnDirection(2)
                turtle.forward()
            else 
                -- move north
                turnDirection(0)
                turtle.forward()
            end
            posX, posY, posZ = gps.locate()
        end
    end
end

--  N,  E,  S, W
--  0,  1,  2,  3
function turnDirection(targetDirection)
    while (getDirection() ~= targetDirection) do
        turtle.turnRight()
        direction = (direction + 1) % 4
    end
end

function turnToPoint(x, z)
    local posX, posY, posZ = gps.locate()

    if (posX ~= x) then
        if (posZ ~= z) then
            print("not in line!")
        end
        if (posX < x) then
            -- need to move east
            turnDirection(1)
        else 
            -- need to move west
            turnDirection(3)
        end
    end
    if (posZ ~= z) then
        if (posZ < z) then
            -- need to move south
            turnDirection(2)
        else 
            -- need to move north
            turnDirection(0)
        end
    end
end

function getDirection()
    -- N, E, S, W
    --  0,  1,  2,  3

    local east = 0
    local south = 0

    if (direction == nil) then
        local posX, posY, posZ = gps.locate()

        if (not turtle.detect()) then
            turtle.forward()
            local posX2, posY2, posZ2 = gps.locate()
            
                if (posX ~= posX2) then
                    if (posX < posX2) then
                        direction = 1
                    else
                        direction = 3
                    end
                end

                if (posZ ~= posZ2) then
                    if (posZ < posZ2) then
                        direction = 2
                    else
                        direction = 0
                    end
                end
        else 
            print("I am blocked")
        end
    end

    print("I am facing " .. direction)
    return direction
end

function goToDiggingLayer()
    local posX, posY, posZ = gps.locate()

    if (posY <= maxDepth) then
        -- done here already
        return
    end

    for i = 1, 2, 1 do 
        while(turtle.detectDown()) do
            turtle.digDown()   
            sleep(0.4)
        end
        turtle.down() 
    end
end

function announceBegin()
    rednet.send(schedulerID, nil, "quarry.announceBegin")
end

function announceFinish()
    rednet.send(schedulerID, nil, "quarry.announceFinish")
end

function getSchedulerPosition()
    rednet.send(schedulerID, nil, "quarry.getSchedulerPosition")

    local senderID, message, protocol = rednet.receive("quarry.getSchedulerPosition")
    print ("received message from ".. senderID .. ", " .. protocol)

    return message
end

function getStripAndMovementChannel()
    rednet.send(schedulerID, nil, "quarry.getStrip")
    print ("sent getStrip message to ".. schedulerID )

    local senderID, message, protocol = rednet.receive("quarry.getStrip")

    print ("received message from ".. senderID .. ", " .. protocol)


    return message
end

function processMessage()

end

function miningLoop()
    -- get new strip
    stripAndMovementChannel = getStripAndMovementChannel()
    local movementChannel = stripAndMovementChannel.movementChannel

    print("movement channel: " .. movementChannel)
    while (stripAndMovementChannel.strip ~= nil) do
        local strip = stripAndMovementChannel.strip
        
        goToMovementChannel(movementChannel)
        print(strip.startX)
        print(strip.startZ)
        navigateTo(strip.startX, strip.startZ)
        goToFloor()
        turnToPoint(strip.endX, strip.endZ)
    
        -- calculate distance to dig
        local distance = math.abs(strip.startX - strip.endX) + math.abs(strip.startZ - strip.endZ)
    
        -- we dig down to 5
        local posX, posY, posZ = gps.locate()
        
        announceBegin()
    
        while (posY > maxDepth) do
            goToDiggingLayer()
            digLayer(distance)
    
            turtle.turnLeft()
            turtle.turnLeft()
            direction = (direction - 2) % 4

            posX, posY, posZ = gps.locate()
        end

        announceFinish()

        stripAndMovementChannel = getStripAndMovementChannel()
    end

    unloadInner()
    goToScheduler(stripAndMovementChannel.movementChannel)
end

function digLayer(distance)
    -- already on pos 1

    

    for i = 1, distance, 1 do
        while(turtle.detectUp()) do
            turtle.digUp()
            unload()
            sleep(0.4)
        end
        
        while(turtle.detectDown()) do
            turtle.digDown()
            unload()
            sleep(0.4)
        end

        if (i < distance) then
            while(turtle.detect()) do
                turtle.dig()
                unload()
                sleep(0.4)
            end
            refuel()
            turtle.forward()
        end
    end

    refuel()
    turtle.down()
end

function unload()
    if (turtle.getItemCount(14) > 0) then
        if unload then
            unloadInner()
        end
    end
end

function unloadInner()
        -- place stronbox
        turtle.digDown()
        turtle.select(unload_slot)
        turtle.placeDown()
        for i=1, 14, 1 do 
            turtle.select(i)

            while (turtle.getItemCount(i) > 0 and not turtle.dropDown()) do
                sleep(.4)
            end
        end
        turtle.select(unload_slot)
        turtle.digDown()
        turtle.select(1)
end

function refuel()
    while (turtle.getFuelLevel() < 1000) do
        unloadInner()
        turtle.select(fuel_slot)
        turtle.placeUp()
        for i=1, 6, 1 do
            turtle.suckUp(64)
            turtle.refuel(64)
        end
        turtle.digUp()
        turtle.select(1)
    end
end

function goToScheduler(movementChannel)
    local schedulerPos = getSchedulerPosition()

    goToMovementChannel(movementChannel)

    navigateTo(schedulerPos.x, schedulerPos.z)

    -- move down until destroyed

    while true do
        refuel()
        turtle.down()
    end
end

function main()
    setup()

    miningLoop()
end

main()