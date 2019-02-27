local enderchestLocation = "bottom"; --needs to be bottom (dropdown)
local mobcrusherLocation = "front";
local modemLocation = "left";

local crusher = peripheral.wrap(mobcrusherLocation);
local chest = peripheral.wrap(enderchestLocation);

function startup()
    rednet.open(modemLocation);
end

function analyeAndMoveConent()
    moveToTurtle();
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
        turtle.dropDown();
    end    
    turtle.select(1);
end

function sendContentUpdate(content)
    if #content > 0 then
        local id = rednet.lookup("contentUpdate", "scheduler");
        local message = textutils.serialize(content);
        print("sending "..message);
        rednet.send(id, message, "contentUpdate");
    end
end

function analyzeContent()
    local content={};

    for i=1, 16 do
        if turtle.getItemCount(i) == 0 then
            return content;
        end

        local data = turtle.getItemDetail(i);
        local itemName = data.name;
        local itemCount = data.count;

        local stacked = false

        for j=1, #content do
            if content[j].item == itemName then
                content[j].count = content[j].count + itemCount;
                stacked = true;
            end
        end

        if not stacked then
            table.insert(content, {item = itemName, count = itemCount});
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