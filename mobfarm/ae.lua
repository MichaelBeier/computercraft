local itemToID ={};

function startup()
    rednet.open("left");
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

function sendNewJobs(content)
    if #content > 0 then
        local text = textutils.serialize(content);
        print(text);
    end

    local messageTable = content;
    
    for i=1, #messageTable do
       sendNewJob(messageTable[i]);
    end
end

function sendNewJob(job)
    local id = rednet.lookup("newJob", "scheduler");
    local message = textutils.serialize(job);
    print("sending "..message);
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
        local damage = data.damage;

        local stacked = false

        for j=1, #content do
            if content[j].dummy == itemName then
                content[j].count = content[j].count + itemCount;
                stacked = true;
            end
        end

        if not stacked then
            table.insert(content, {priority="AE", count=itemCount, dummy=itemName, dummyDamage=damage});
        end
    end

    return content;
end


startup();
while true do
    turtle.select(1);
    os.sleep(1);
    local jobs = analyeAndMoveConent();
    sendNewJobs(jobs);
end