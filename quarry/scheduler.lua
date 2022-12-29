-- todo on turtle place, get their id and use the launcher to start the quarry worker program
-- todo give turtles enderchests

-- select size (32x32, 64x64, 128x128)
-- select which corner the computer is in (NE, SE, SW, NW)
-- auto detect + warn for wonky chunk border?

-- have list of workers that enlist with the scheduler
-- woker can request a strip (get start x,z, (y from gps location of scheduler), end x,z,0)
-- workers will dig down two, then we strip along until the end coordinate, then down 2 and back to beginning until at 0
-- after that, go back up, request new strip, move to beginning and do stuff

-- collision avoidance system
-- when assigning a new strip, scheduler gives a y level so each turtle is moving on a different one

-- events:
-- getStrip
--      can return a nil value when all strips are finished/being worked on -> turtle will return to scheduler turtle to get destroyed and stored
-- announceBegin
-- announceFinish
-- update 
--      return number of blocks mined since last update message
-- abort
--      make all turtles return to scheduler


-- scheduler: keep track of list of strips that need to be worked on
-- scheduler is a turtle, with chest with workers underneath
  



-- scheduler logic

local schedulerHostname = "quarry.scheduler1"
local modemSide = "left"
local workerPlacingPosition = "top"
local workerChestPosition = "bottom"

local finished = false

local schedulerX, schedulerY, schedulerZ = gps.locate()

local strips = {}

local movementChannels = {}

local totalStrips = 0
local progressStrips = 0

local currentWorkers = 0

function setup() 

    finished = false
    strips = {}
    movementChannels = {}
    totalStrips = 0
    progressStrips = 0
    currentWorkers = 0

    rednet.open(modemSide)
    renderUI()
    rednet.host(schedulerHostname, schedulerHostname)

    createMovementChannels()
end

function renderUI()
    
end

function userInput()
    print("enter size (e.g. 32)")
    local size = tonumber(io.read())
    -- 32, 64, 128
    
    print("enter scheduler position (e.g. 2)")
    print("NE = 0, SE = 1, SW = 2, NW = 3")
    local corner = tonumber(io.read())
    -- corner in which scheduler is!
    -- NE, SE, SW, NW
    --  0,  1,  2,  3

    local bottomLeft = {}
    local topRight = {}

    if (corner == 0) then
        topRight = {x = schedulerX - 1, z = schedulerZ - 1}
        bottomLeft = {x = schedulerX - 1 - size, z = schedulerZ + 1 + size}
    end

    if (corner == 1) then
        topRight = {x = schedulerX - 1, z = schedulerZ - 1 - size}
        bottomLeft = {x = schedulerX - 1 - size, z = schedulerZ - 1}
    end

    if (corner == 2) then
        topRight = {x = schedulerX + size + 1, z = schedulerZ - size - 1}
        bottomLeft = {x = schedulerX + 1, z = schedulerZ - 1}
    end

    if (corner == 3) then
        topRight = {x = schedulerX + size + 1, z = schedulerZ - 1}
        bottomLeft = {x = schedulerX + 1, z = schedulerZ - 1 - size}
    end

    createStrips(bottomLeft, topRight)
end

function createMovementChannels()
    for i = schedulerY+2, 256, 1 do
        movementChannels[i] = 0
    end
end

function createStrips(bottomLeft, topRight)
    -- turtles start on x axis

    print(bottomLeft.x)
    print(topRight.x)

    for i = bottomLeft.x, topRight.x, 1 do
        local strip = {
            startX = i,
            startZ = bottomLeft.z,
            endX = i,
            endZ = topRight.z
        }

        print(strip.startX .. strip.startZ)
        print(strip.endX .. strip.endZ)
        
        table.insert(strips, strip)
    end

    totalStrips = #strips
end

function processMessage(senderID, message, protocol)
    print ("received message from ".. senderID .. ", "  .. protocol)

    if (protocol == "quarry.getStrip") then
        processGetStrip(senderID)
    end

    if (protocol == "quarry.announceBegin") then
        processAnnounceBegin(senderID)
    end

    if (protocol == "quarry.announceFinish") then
        processAnnounceFinish(senderID)
    end

    if (protocol == "quarry.getSchedulerPosition") then
        processGetSchedulerPosition(senderID)
    end
end

function processGetSchedulerPosition(senderID)
    rednet.send(senderID, {x = schedulerX, z = schedulerZ}, "quarry.getSchedulerPosition")
end

function getMovementChannel(senderID)
    for k,v in pairs(movementChannels) do 
        if (v == 0) then
            movementChannels[k] = senderID
            return k
        end
    end

    return -1
end

function processGetStrip(senderID) 
    local message = {}
    local strip = {}
    print(#strips)

    if (#strips == 0) then
        -- no more strips to distribute, the turtle can return to the scheduler
        strip = nil
    else 
        strip = table.remove(strips)
    end

    message = {
        strip = strip,
        movementChannel = getMovementChannel(senderID)
    }

    rednet.send(senderID, message, "quarry.getStrip")
end

function processAnnounceBegin(senderID)
    -- senderID begins digging message
    -- clear movementChannel

    currentWorkers = currentWorkers + 1

    for k,v in pairs(movementChannels) do 
        if (v == senderID) then
            movementChannels[k] = 0
            return
        end
    end
end

function processAnnounceFinish(senderID)
    -- update status

    progressStrips = progressStrips + 1
    currentWorkers = currentWorkers -1

end

function header()
    print("---------------------------------------")
    print("    Basti's awesome quarry program!    ")
    print("               Scheduler               ")
    print("---------------------------------------")
end

function renderStatus()
    -- calculate volume based on 
end

function placeTurtles()
    -- enderchest out
    turtle.select(1)
    turtle.suckDown()

    -- enderchest fuel
    turtle.select(2)
    turtle.suckDown()

    turtle.select(3)
    while (turtle.suckDown()) do
        while (turtle.detectUp()) do
            sleep(.2)
        end
        turtle.placeUp()

        sleep(.4)

        turtle.select(1)
        turtle.dropUp(1)

        turtle.select(2)
        turtle.dropUp(1)

        peripheral.call("top", "turnOn")

        -- wait for getStrip
        local senderID, message, protocol = rednet.receive("quarry.getStrip")

        processMessage(senderID, message, protocol)
        currentWorkers = currentWorkers + 1

        turtle.select(3)
    end
end

function showEndScreen()
    os.run("clear")

    header()
    print("Quarry is done!")
    print("Press any key to exit program...")
    io.read()
end


function main()
    setup()
    userInput()
    placeTurtles()
    while (not finished) do
        local senderID, message, protocol = rednet.receive()
        processMessage(senderID, message, protocol)
        if (currentWorkers == 0 and progressStrips == totalStrips) then
            finished = true
        end
        renderUI()
    end

    showEndScreen()
end

while true do
    main()
end