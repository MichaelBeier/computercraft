local enderchestLocation = "bottom"; --needs to be bottom (dropdown)
local mobcrusherLocation = "front";

local crusher = peripheral.wrap(mobcrusherLocation);
local chest = peripheral.wrap(enderchestLocation);

function analyeAndMoveConent()
    moveToTurtle();
    local content = analyzeContent();
    moveToChest();
end

function moveToTurtle()
    for i=1, 16 do
        turtle.suck();
    end
end

function moveToChest()
    for i=1, 16 do
        turtle.dropDown();
    end    
end

function sendContentUpdate(content)
    if content ~= nil then
        print("not nil");
        local text = textutils.serialize(content);
        print(text);
    end
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
            print("not stacked");
            table.insert(content, {itemName, itemCount});
            local text = textutils.serialize(content);
            print(text);
        end
    end

    return content;
end

while true do
    os.sleep(1);
    local content = analyeAndMoveConent();
    sendContentUpdate(content);
end