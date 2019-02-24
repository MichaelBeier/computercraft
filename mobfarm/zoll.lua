local enderchestLocation = "right";
local mobcrusherLocation = "back";

local crusher = peripheral.wrap(mobcrusherLocation);
local chest = peripheral.wrap(enderchestLocation);

function analyeAndMoveConent()
    moveToTurtle()
    local content = analyzeContent()
end

function moveToTurtle()
    for i=1, 16 do
        turtle.suck()
    end
end

function analyzeContent()
    local content;

    for i=1, 16 do
        if turtle.getItemCount(i) == 0 then
            return content;
        turtle.getItemDetail(i);
        table.insert(content,)
    end
end

while true do
    local content = analyeAndMoveConent();
    sendContentUpdate();
end