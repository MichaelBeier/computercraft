local chestLocation = "bottom";
local spawnerLocation = "front";


local spawner = peripheral.wrap(spawnerLocation);
local chest = peripheral.wrap(chestLocation);
local currentJob=0;

function cleanUp()
    turtle.select(1);
    turtle.suck();
    if turtle.getItemCount(1) > 0 then
        -- there was an item in the mobfarm
        local index = findOldItemPlace();
        putItemBack(index);
    end
end

function findOldItemPlace()
    local chestContent = chest.list();
    local oldKey = 0;

    for key, value in pairs(chestContent) do
        
        if key ~= oldKey+1 then
            return key-1;
        end

        oldKey = key;
    end

    return oldKey+1;
end

function putItemBack(index) 
    print("old item index: ".. index);
    turtle.dropDown(); -- puts into first slot of chest
    chest.pushItems(chestLocation, 1, index);
end

function startup()
    rednet.open("left");
    cleanUp();
end

function getJob()
    --placeholder
    print("get Job");
    local id = rednet.lookup("currentJob", "scheduler");
    local message = "";
    rednet.send(id, message, "currentJob");

    local senderID, answer, protocol;

    while protocol ~= "currentJob" do
        senderID, answer, protocol = rednet.receive()
    end
     
    return answer;
end

function changeJob(newJob)
    print(newJob[1]);
    if newJob ~= currentJob then
        unloadJob()
        currentJob = newJob;
        loadJob()
    end
end

function unloadJob()
    if currentJob == 0 then
        return 1;
    end

    turtle.suck();
    putItemBack(currentJob[1]);
end

function loadJob()
    if currentJob ~= 0 then
        chest.pushItems(spawnerLocation, currentJob, 1);
    end
end

function moveToFront()
    -- moves turtle to user acessible position to put a new mob into the system

end

startup();
while true do
    local newJob = getJob();
    changeJob(newJob);
    os.sleep(1);
end
