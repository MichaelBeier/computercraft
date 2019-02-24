local chestLocation = "bottom";
local spawnerLocation = "front";


local spawner = peripheral.wrap(spawnerLocation);
local chest = peripheral.wrap(chestLocation);
local safariNets = {};
local currentJob={0,0};

function downloadConfig()
    os.loadAPI("startup");

    local content = download("https://gitlab.com/michaelbeier/computercraftcollection/raw/master/mobfarm/worker_config")
    local configHandle = fs.open("config", "w");
    configHandle.write(content);
    configHandle.flush();
    configHandle.close();
end

function loadConfig()
    downloadConfig();

    if not fs.exists("config") then
        safariNets = {"NICHTSDAMITERNICHTAUSVERSEHENMATCHT", "witherSkeleton", "pinkSlime"};
        local configHandle = fs.open("config", "w");
        configHandle.write(textutils.serialize(safariNets));
        return;
    end

    local configHandle = fs.open("config", "r");
    local configContent = configHandle.readAll();
    local config = textutils.unserialize(configContent);

    configHandle.close();

    safariNets = config;
end

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
    loadConfig();
    cleanUp();
end

function getJob()
    --placeholder
    print("get Job");
    local job = {"pink", 64};
    print(job[1] .. job[2]);
    return translateJob(job);
end

function translateJob(job)
    print("translate job");
    local slot = findSlot(job[1]);
    
    if slot == 0 then
        return nil
    end

    return {slot, job[2]};
end

function findSlot(text)
    print("find slot for " .. text);
    for i=1, #safariNets do
        print("safari: ".. safariNets[i]);
        if string.find(safariNets[i], text) then
            print("found slot");
            return i;
        end
    end
    return 0
end

function changeJob(newJob)
    print(newJob[1] .. " ".. newJob[2]);
    if newJob[1] ~= currentJob[1] or newJob[2] ~= currentJob[2] then
        unloadJob()
        currentJob = newJob;
        loadJob()
    end
end

function unloadJob()
    if currentJob[1] == 0 and currentJob[2] == 0 then
        return 1;
    end

    turtle.suck();
    putItemBack(currentJob[1]);
end

function loadJob()
    chest.pushItems(spawnerLocation, currentJob[1], 1);
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
