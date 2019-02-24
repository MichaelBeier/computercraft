local jobs = {}
local modemside = "top";

local priomapping = {"user", "AE"};

function startup()
    rednet.open("top");
    rednet.host("newJob", "scheduler");
    rednet.host("jobQuery", "scheduler");
    rednet.host("currentJob", "scheduler");
    rednet.host("contentUpdate", "scheduler");
end

-- todo close jobs if empty, react to contentupdate, pause jobs

function processMessage(message, protocol)
    if protocol == "jobQuery" then
        return textutils.serialize(jobs);
    elseif protocol == "newJob" then
        local job = textutils.unserialize(message);
        print("new job is this:" .. message);
        -- {priority ("user", AE"), id, count, item, }
        -- {priority, count, item, progress}

        if #jobs == 0 then
            print("currently no other jobs");
            local translated = translateJob(job);
            table.insert(jobs, translated);
        else
            local translated = translateJob(job);
            for i=1, #jobs do
                if jobs[i][1] > translated[1] then
                    return table.insert(jobs, i, translated);
                end
            end
            return table.insert(jobs, translated);
        end
    elseif protocol == "currentJob" then
        print("received query from worker")
        if #jobs > 0 then
            local mob = findMob(job[1]);
            print("sending to worker: " .. textutils.serialize(mob));
            return textutils.serialize(mob);
        else 
            return {0};
        end
    elseif protocol == "contentUpdate" then
        print("received contentUpdate");
        content = textutils.serialize(message);
        
        for i = 1, #content do
            for j = 1, #jobs do
                if jobs[j][3] == content[i][1] then
                    jobs[j][4] = jobs[j][4] + content[i][2];
                    break;
                end
            end
        end
        for j = 1, #jobs do
            if jobs[j][4] >= jobs[j][2] then
                -- job finished
                table.remove(jobs, j);
                break;
            end
        end

    end
end

function translateJob(job)
    local translated = job;
    translated[1] = getPrio(job[1]);
    return translated;
end

function getPrio(text)
    for i = 1, #priomapping do
        if priomapping[i] == text then
            return i;
        end
    end
    return 0;
end

startup();
while true do
    print(textutils.serialize(jobs));
    local senderID, message, protocol = rednet.receive()

    local response = processMessage(message, protocol);

    if response then
        rednet.send(senderID, response, protocol);
    end
end