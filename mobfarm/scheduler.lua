local jobs = {}
local modemside = "top";
local schedulerConfig;

local priomapping = {"user", "AE"};

function startup()
    loadConfig();
    rednet.open("top");
    rednet.host("newJob", "scheduler");
    rednet.host("jobQuery", "scheduler");
    rednet.host("currentJob", "scheduler");
    rednet.host("contentUpdate", "scheduler");
    rednet.host("getConfig", "scheduler");
end

-- todo close jobs if empty, react to contentupdate, pause jobs

function processMessage(message, protocol)
    if protocol == "jobQuery" then
        print("received jobQuery")
        return textutils.serialize(jobs);
    elseif protocol == "newJob" then
        local job = textutils.unserialize(message);
        print("new job is this:" .. message);
        -- {priority, count, item, progress}
        
        job.progress=0;
        local translated = translateJob(job);

        if #jobs == 0 then
            table.insert(jobs, translated);
        else
            for i=1, #jobs do
                if jobs[i].priority > translated.priority then
                    return table.insert(jobs, i, translated);
                end
            end
            return table.insert(jobs, translated);
        end

    elseif protocol == "currentJob" then
        print("received query from worker")
        if #jobs > 0 then
            local slot = jobs[1].toolSlot;
            print("sending to worker: " .. slot);
            return slot;
        else 
            return 0;
        end
    elseif protocol == "contentUpdate" then
        print("received contentUpdate");
        content = textutils.unserialize(message);
        
        for i = 1, #content do
            for j = 1, #jobs do
                if jobs[j].item == content[i].item and jobs[j].itemDamage == content[i].itemDamage then
                    jobs[j].progress = jobs[j].progress + content[i].count;
                    break;
                end
            end
        end
        for j = #jobs, 1, -1 do
            if jobs[j].progress >= jobs[j].count then
                -- job finished
                table.remove(jobs, j);
            end
        end
    
    elseif protocol == "getConfig" then
        print("received config query");
        return textutils.serialize(schedulerConfig);
    end
end

function fillJobInfo(job)
    for i = 1, #schedulerConfig do
        if schedulerConfig[i].item == job.item then
            job.dummy = schedulerConfig[i].dummy;
            job.dummyDamage = schedulerConfig[i].dummyDamage;
            job.toolSlot = schedulerConfig[i].toolSlot;
            job.displayName = schedulerConfig[i].displayName;
            job.mobID = schedulerConfig[i].mobID;
        end
    end

    for i = 1, #schedulerConfig do
        if schedulerConfig[i].dummy == job.dummy then
            job.item = schedulerConfig[i].item;
            job.itemDamage = schedulerConfig[i].itemDamage;
            job.toolSlot = schedulerConfig[i].toolSlot;
            job.displayName = schedulerConfig[i].displayName;
            job.mobID = schedulerConfig[i].mobID;
        end
    end

    return job;
end

function downloadConfig()
    local content = download("https://gitlab.com/michaelbeier/computercraftcollection/raw/master/mobfarm/scheduler_config")
    local configHandle = fs.open("config", "w");
    configHandle.write(content);
    configHandle.flush();
    configHandle.close();
end

function download(url)
	local httpResponse = http.get(url)

	local statusCode = httpResponse.getResponseCode()

	if statusCode ~= 200 then
		return nil
	end

	local scriptContent = httpResponse.readAll()
	return scriptContent
end

function loadConfig()
    downloadConfig();

    local configHandle = fs.open("config", "r");
    local configContent = configHandle.readAll();
    local config = textutils.unserialize(configContent);

    configHandle.close();

    schedulerConfig = config;
end

function translateJob(job)
    local translated = job;
    translated.priority = getPrio(job.priority);

    translated = fillJobInfo(job);

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