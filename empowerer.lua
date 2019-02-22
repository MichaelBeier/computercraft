local recipes = {
	{"actuallyadditions:block_crystal", "ic2:plate", "tconstruct:ingots", "tconstruct:slime_congealed", "biomesoplenty:gem" }, --empowered palis
	{"mekanism:atomicalloy", "mekanism:controlcircuit", "mekanism:controlcircuit", "mekanism:controlcircuit", "mekanism:controlcircuit"}, --ultimate control circuit
}

function checkForRecipe()
    for i=1,#recipes do
        print("checking recipe #" .. i);
        local neededMatches = #recipes[i];
        print("needed: " .. neededMatches);
        local matches = 0;
        for j=1, #recipes[i] do
            local found = findItem(recipes[i][j]);
            if (found) then
                matches = matches+1;
            end
        end
        print("found: " .. matches);
        if (matches == neededMatches) then
            return i;
        end
    end
    return false;
end

function findItem(wanted)
    for k = 1, 16 do
        if (turtle.getItemCount(k) > 0) then
            local data = turtle.getItemDetail(k);
            local name = data.name;
            local found = string.find(name, wanted);
            if (found) then
                return k;
            end
        end
    end
end

function moveForward(number)
    for i = 1,number do
        turtle.forward()
    end
end

function dropItem(wanted)
    local slot = findItem(wanted);
    turtle.select(slot);
    while turtle.dropDown() == false do
        os.sleep(1);
    end
    turtle.select(1);
end

function craft(recipe)
    local items = recipes[recipe];
    moveForward(3);
    dropItem(items[2]);
    moveForward(3);
    turtle.turnLeft();
    moveForward(3);
    dropItem(items[3]);
    moveForward(3);
    turtle.turnLeft();
    moveForward(3);
    dropItem(items[4]);
    turtle.turnLeft();
    moveForward(3);
    dropItem(items[1]);
    turtle.turnRight();
    moveForward(3) ;
    dropItem(items[5]);
    turtle.turnLeft();
    moveForward(3);
    turtle.turnLeft();
end

while true do
    turtle.select(1);
    if (turtle.getItemCount(1) == 0) then
        os.sleep(1);
    else
        local recipe = checkForRecipe();
        if (recipe == false) then
            
        else
            craft(recipe);
        end
    end
end