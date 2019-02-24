local jobs = {}
local modemside = "top";

local priomapping = {"user", "AE"};

function startup()
    rednet.open("top");
end

function processMessage(message, protocol)
    if protocol == "jobQuery" then
        return textutils.serialize(jobs);
    elseif protocol == "newJob" then
        local job = textutils.unserialize(message);
        print("new job is this:" .. job);
        -- {priority ("user", AE"), id, count}

        if #jobs == 0 then
            local translated = translateJob(job);
            table.insert(jobs, translated);
        else
            local translated = translateJob(job);
            for i=1, #jobs do
                if jobs[i][1] > translated[1] then
                    table.insert(jobs, i, translated);
                end
            end
        end
    elseif protocol == "currentJob" then
        if #jobs > 0 then
            return textutils.serialize(jobs[1]);
        end
    end
end

function translateJob(job)
    local translated = job;
    translated[1] = priomapping[job[1]];
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