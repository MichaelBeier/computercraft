local deployerName = "create:deployer_81"
local deployer = peripheral.wrap(deployerName)

local deployerDepotName = "create:depot_1"
local deployerDepot = peripheral.wrap(deployerDepotName)

local pressDepotName = "create:depot_2"
local pressDepot = peripheral.wrap(pressDepotName)

local sawName = "create:saw_0"
local saw = peripheral.wrap(sawName)

local sawOutputName = "create:depot_3"
local sawOutput = peripheral.wrap(sawOutputName)

local sawItemName = "create:mechanical_saw"
local pressItemName = "create:mechanical_press"
local deployerItemName = "create:deployer"

local recipeChestName = "ironchest:gold_chest_3"
local recipeChest = peripheral.wrap(recipeChestName)

local orderInputChestName = "ironchest:gold_chest_4"
local orderInputChest = peripheral.wrap(orderInputChestName)

local orderOutputChestName = "ironchest:iron_chest_0"
local orderOutputChest = peripheral.wrap(orderOutputChestName)

local recipePath = "/create/sequenced_assembly/recipes/"
local recipes = {}

function hasNewRecipe()
    local contents =  recipeChest.list()
    return tablelength(contents) > 0
end

function hasNewOrder() 
    local contents =  orderInputChest.list()
    return tablelength(contents) > 0
end

function do_tables_match( a, b )
    return textutils.serialise(a) == textutils.serialise(b)
end

function main()

    if not fs.exists(recipePath) then
        fs.makeDir(recipePath)
    end
    loadRecipes()

    while true do

        if hasNewRecipe() then
            local recipe = getNewRecipe()

            for _, rec in pairs(recipes) do
                if do_tables_match(rec, recipe) then
                    alreadyKnown = true
                end
            end
        
            if not alreadyKnown then
                storeRecipe(recipe)
                print("stored new recipe")
            end
        end

        if hasNewOrder() then
            local recipe = getRequestedRecipe()
            if recipe ~= nil then
                print("new order, start crafting")
                craftRecipe(recipe["recipe"])
            end
        end

        os.sleep(1)
    end
end

function getRequestedRecipe()
    local contents =  orderInputChest.list()
    local conciseList = getConciseListFromChest(contents)

    for _, recipe in pairs(recipes) do
        local conciseRecipeList = recipe["ingredientsList"]
        local match = true
        
        for itemName, itemCount in pairs(conciseRecipeList) do
            if conciseList[itemName] == nil or conciseList[itemName] < itemCount then
                --print(itemName .. " in chest: " .. conciseList[itemName] .. " in recipe " .. itemCount)
                match = false
                break
            end 
        end

        if match then
            return recipe
        end
    end

    return nil
end

function getConciseListFromChest(ingredientsTable)
    local conciseList = {}

    for key, value in pairs(ingredientsTable) do
        local itemName = value["name"]
        if conciseList[itemName] == nil then
            conciseList[itemName] = 0
        end

        conciseList[itemName] = conciseList[itemName] + value["count"]
    end
    return conciseList
end

function craftRecipe(recipe) 
    local startingItem = recipe["startItem"]
    local fromSlot = findItemInInventory(startingItem, orderInputChest)
    
    local from = orderInputChest
    
    for i = 1, recipe["count"], 1 do 
        for _, step in pairs(recipe["steps"]) do
            local to = getWorkstationPeripheral(step["workstation"])
    
            from.pushItems(peripheral.getName(to), fromSlot, 1, 1)
    
            if step["item"] ~= nil then
                local additionInput = getWorkstationAdditionalInputPeripheral(step["workstation"])
                orderInputChest.pushItems(peripheral.getName(additionInput), findItemInInventory(step["item"], orderInputChest), 1, 1)
            end
    
            from = getExpectedOutputPeripheral(step["workstation"])
            fromSlot = 1
            os.sleep(.5)
        end
    end

    from.pushItems(peripheral.getName(orderOutputChest), fromSlot)
end

function getExpectedOutputPeripheral(workstationName)
    if workstationName == "create:mechanical_saw" then
        return sawOutput
    elseif workstationName == "create:mechanical_press" then
        return pressDepot 
    elseif workstationName == "create:deployer" then
        return deployerDepot
    end
end

function getWorkstationPeripheral(workstationName)
    if workstationName == "create:mechanical_saw" then
        return saw
    elseif workstationName == "create:mechanical_press" then
        return pressDepot 
    elseif workstationName == "create:deployer" then
        return deployerDepot
    end
end

function getWorkstationAdditionalInputPeripheral(workstationName)
    if workstationName == "create:deployer" then
        return deployer
    end
    return nil
end

-- returns index
function findItemInInventory(itemName, peripheral)
    local inventory = peripheral.list()
    local inventorySize = peripheral.size()

    for i = 1, inventorySize, 1 do
        local item = inventory[i]
        if item ~= nil then
            if item["name"] == itemName then
                return i
            end
        end
    end
    return -1
end

function getNewRecipe()
    local startItem = getStartItem(recipeChest)
    local steps = getSteps(recipeChest)

    print("How often should the sequence be repeated?")
    count = tonumber(read())

    local recipe = {["startItem"] = startItem, ["steps"] = steps, ["count"] = count}
    return recipe
end

function getStartItem()
    local inventory = recipeChest.list()
    local item = inventory[1]
    return item["name"]
end

function getSteps()
    local inventory = recipeChest.list()
    local inventorySize = recipeChest.size()
    local steps = {}
    
    -- 2 because 1 is the starting item
    local skipNext = false

    for i = 2, inventorySize, 1 do
        if skipNext then 
            skipNext = false
        else
            local item = inventory[i]
            local step = {["workstation"] = nil, ["item"] = nil}

            if item == nil then
                return steps
            else 
                step["workstation"] = item["name"]
                if item["name"] == deployerItemName then
                    step["item"] = inventory[i+1]["name"]
                    skipNext = true
                end
                table.insert(steps, step)
            end
        end
    end
end

function storeRecipe(recipe)
    local nextNumber = getNextRecipeNumber()
    local fileName = recipePath .. "recipe" .. nextNumber

    local ingredientsList = getConciseList(recipe)

    local finalTable = {["recipe"] = recipe, ["ingredientsList"] = ingredientsList}
    table.insert(recipes, finalTable)

    local file = fs.open(fileName, "w")
    file.write(textutils.serialise(finalTable))
    file.flush()
    file.close()
end

function getConciseList(recipe)
    local conciseList = {}

    for key, step in pairs(recipe["steps"]) do
        local itemName = step["item"]
        if itemName ~= nil then
            if conciseList[itemName] == nil then
                conciseList[itemName] = 0
            end
            conciseList[itemName] = conciseList[itemName] + recipe["count"]
        end
    end

    conciseList[recipe["startItem"]] = 1

    return conciseList
end


function loadRecipes() 
    local files = fs.list(recipePath)

    for i = 1, #files do
        loadRecipe(recipePath..files[i])
    end
end

function loadRecipe(fileName)
    local file = fs.open(fileName, "r")

    table.insert(recipes, textutils.unserialise(file.readAll()))

    file.close()
end

function getNextRecipeNumber()
    local fileTable = fs.list(recipePath)
    return tablelength(fileTable) + 1
end

function tablelength(T)
    local count = 0
    for _ in pairs(T) do count = count + 1 end
    return count
end

main()