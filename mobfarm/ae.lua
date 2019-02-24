local itemToID ={};

function downloadConfig()
    local content = download("https://gitlab.com/michaelbeier/computercraftcollection/raw/master/mobfarm/ae_config")
    local configHandle = fs.open("config", "w");
    configHandle.write(content);
    configHandle.flush();
    configHandle.close();
end

function startup()
    rednet.open("left");
    loadConfig();
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

    itemToID = config;
end

function analyeAndMoveConent()
    local content = analyzeContent();
    if #content > 0 then
        moveToChest();
    end
    return content;
end

function moveToTurtle()
    for i=1, 16 do
        turtle.suck();
    end
end

function moveToChest()
    for i=1, 16 do
        turtle.select(i);
        turtle.drop();
    end    
    turtle.select(1);
end

function sendContentUpdate(content)
    if #content > 0 then
        local text = textutils.serialize(content);
        print(text);
    end

    local messageTable = content;
    
    for i=1, #messageTable do
        messageTable[i][2] = getID(messageTable[i][2]); 
    end

    for i=1, #messageTable do
       sendNewJob(messageTable[i]);
    end
end

function getID(text)
    for i = 1, #itemToID do
        if itemToID[i][1] == text then
            return itemToID[i][2];
        end
    end
    return 0;
end

function sendNewJob(job)
    local id = rednet.lookup("newJob", "scheduler");
    local message = textutils.serialize(job);
    rednet.send(id, message, "newJob");
end

function analyzeContent()
    local content = {};

    for i=1, 16 do
        if turtle.getItemCount(i) == 0 then
            return content;
        end

        local data = turtle.getItemDetail(i);
        local itemName = data.name;
        local itemCount = data.count;

        local stacked = false

        for j=1, #content do
            if content[j][1] == itemName then
                content[j][2] = content[j][2] + itemCount;
                stacked = true;
            end
        end

        if not stacked then
            table.insert(content, {itemName, itemCount});
        end
    end

    return content;
end


startup();
while true do
    turtle.select(1);
    os.sleep(1);
    local content = analyeAndMoveConent();
    sendContentUpdate(content);
end