--
--  00 01 02 ..
--  09
--
-- 
--  ..           80

local newRecipeChestDirection = "ironchest:gold_chest_2"
local newOrderChestDirection = "ironchest:gold_chest_1"
local coverChestDirection = "industrialforegoing:common_black_hole_unit_0"
local outputChestDirection = "minecraft:chest_0"
local clutchRedstoneDirection = "left"
local crafterOutputName = "create:depot_0"

local recipePath = "/create_mech_crafting/recipes/"
local mappingRootPath = "/create_mech_crafting/mappings/"
--local crafterMappingPath = mappingRootPath.."crafter"
local deployerMappingPath = mappingRootPath.."deployer"

local recipeChest
local orderChest
local coverChest
local outputChest
local crafterOutput

--local crafterMapping
local deployerMapping

local recipes = {}

function init()
    setupPeripherals() 

    if not fs.exists(recipePath) then
        fs.makeDir(recipePath)
    end
    if not fs.exists(mappingRootPath) then
        fs.makeDir(mappingRootPath)
    end

    loadMappings()
    loadRecipes()
end

function loadMappings()
    --local crafterMappingFile = fs.open(crafterMappingPath, "r")
    local deployerMappingFile = fs.open(deployerMappingPath, "r")

    --crafterMapping = crafterMappingFile.readAll()
    deployerMapping = textutils.unserialise(deployerMappingFile.readAll())

    print(deployerMapping[6])
    
    deployerMappingFile.close()
end

function setupPeripherals() 
    recipeChest = peripheral.wrap(newRecipeChestDirection)
    orderChest = peripheral.wrap(newOrderChestDirection)
    coverChest = peripheral.wrap(coverChestDirection)
    outputChest = peripheral.wrap(outputChestDirection)
    crafterOutput = peripheral.wrap(crafterOutputName)
end

--function emptyAllCrafters()
--    for index=0,80,1 do
--        local actualCrafterIndex = getMappedCrafterIndex(index)
--        local item = peripheral.call("create:mechanical_crafter"..actualCrafterIndex, "getItemDetail", 1)
--    
        --TODO item name?
--        if item["name"] == "create:crafter_slot_cover" then
--            coverChest.pullItems("create:mechanical_crafter"..actualCrafterIndex, 1, 1)
--        else 
--            outputChest.pullItems("create:mechanical_crafter"..actualCrafterIndex, 1, 1)
--        end
--    end
--end

function main()
    init()

    emptyAllDeployers()

    while true do
        -- check if new recipe
        if hasNewRecipe() then
            -- TODO get user input when done
            registerNewRecipe()
        end
        -- check if new order
        if hasNewOrder() then
            local recipe = getRecipe()
            if recipe ~= nil then
                print("new order, start crafting")
                craftRecipe(recipe)
            end
        end
    end
end

function hasNewOrder() 
    local contents =  orderChest.list()
    return tablelength(contents) > 0
end

function do_tables_match( a, b )
    return textutils.serialise(a) == textutils.serialise(b)
end

function getRecipe()
    local contents =  orderChest.list()
    local conciseList = getConciseList(contents)

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

function craftRecipe(recipe)
    placeItemsInDeployers(recipe)
    placeCoversInDeployers(recipe)

    pulseAllDeployers()
    waitForCraft()
    transferResult()

    pulseAllDeployers()
    emptyAllDeployers()
end

function waitForCraft()
    local contents =  crafterOutput.list()
    while #contents == 0 do
        contents =  crafterOutput.list()
        os.sleep(1)
    end
end

function transferResult()
    crafterOutput.pushItems(outputChestDirection, 1, 1)
end

function placeItemsInDeployers(recipe)
    for index, item in pairs(recipe["recipe"]) do
        findAndMoveItem(index, item["name"])
    end
end

function findAndMoveItem(deployerIndex, itemName)
    local actualDeployerIndex = getMappedDeployerIndex(deployerIndex)
    local orderContents = orderChest.list()
    for index, item in pairs(orderContents) do
        if item["name"] == itemName then
            orderChest.pushItems("create:deployer_"..actualDeployerIndex, index, 1)
            return
        end
    end
end

function placeCoversInDeployers(recipe)
    for index=1,81,1 do
        if needsCover(index, recipe) then
            fillDeployer(index)
        end
    end
end

function fillDeployer(deployerIndex)
    local actualDeployerIndex = getMappedDeployerIndex(deployerIndex)

    coverChest.pushItems("create:deployer_"..actualDeployerIndex, 1, 1)
end

function emptyAllDeployers()
    for index=1,81,1 do
        local actualDeployerIndex = getMappedDeployerIndex(index)
        local item = peripheral.call("create:deployer_"..actualDeployerIndex, "getItemDetail", 1)

        if item ~= nil then
            if item["name"] == "create:crafter_slot_cover" then
                coverChest.pullItems("create:deployer_"..actualDeployerIndex, 1, 1)
            else 
                outputChest.pullItems("create:deployer_"..actualDeployerIndex, 1, 1)
            end
        end
    end
end

function pulseAllDeployers()
    redstone.setOutput(clutchRedstoneDirection, true)
    os.sleep(1.5)
    redstone.setOutput(clutchRedstoneDirection, false)
end

function needsCover(crafterIndex, recipe)
    local actualRecipe = recipe["recipe"]
    return actualRecipe[crafterIndex] == nil
end

--function getMappedCrafterIndex(crafterIndex)
--    return crafterMapping[crafterIndex]
--end

function getMappedDeployerIndex(deployerIndex)
    return deployerMapping[deployerIndex]
end


function hasNewRecipe()
    local contents =  recipeChest.list()
    return tablelength(contents) > 0
end

function registerNewRecipe()
    local ingredients = recipeChest.list()
    local alreadyKnown = false

    for _, recipe in pairs(recipes) do
        if do_tables_match(recipe["recipe"], ingredients) then
            alreadyKnown = true
        end
    end

    if not alreadyKnown then
        storeRecipe(ingredients)
        print("stored new recipe")
    end
end

function storeRecipe(ingredientsTable)
    local nextNumber = getNextRecipeNumber()
    local fileName = recipePath .. "recipe" .. nextNumber

    local ingredientsList = getConciseList(ingredientsTable)

    local finalTable = {["recipe"] = ingredientsTable, ["ingredientsList"] = ingredientsList}
    table.insert(recipes, finalTable)

    local file = fs.open(fileName, "w")
    file.write(textutils.serialise(finalTable))
    file.flush()
    file.close()
end

function getConciseList(ingredientsTable)
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