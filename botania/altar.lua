local input = peripheral.wrap("minecraft:barrel_3")
local craftChest = peripheral.wrap("minecraft:barrel_4")
local output = peripheral.wrap("refinedstorage:interface_1")
local vacuum = peripheral.wrap("thermal:device_collector_0")

local vacuumSide = "front"
local crafterSide = "left"

function execute()
	local slotsUsed = tableLength(input.list())

	print("waiting for items")

	if slotsUsed == 0 then
		os.sleep(2)
		return
	end

	print("starting crafting")

	for slot, _ in pairs(input.list()) do
		input.pushItems(peripheral.getName(craftChest), slot)
	end

	os.sleep(slotsUsed)

	print("enabling vacuum")

	redstone.setAnalogOutput(vacuumSide, 15)

	while true do
		local addedItems = vacuum.getItemDetail(1) ~= nil

		if addedItems then
			break
		end
	end

	print("disabling vacuum")

	redstone.setAnalogOutput(vacuumSide, 0)

	print("pushing items to output")

	vacuum.pushItems(peripheral.getName(output), 1)

	print("pulsing crafter redstone signal")

	redstone.setAnalogOutput(crafterSide, 15)
	os.sleep(1)
	redstone.setAnalogOutput(crafterSide, 0)
end

function tableLength(table)
	local count = 0
	for _ in pairs(table) do
		count = count + 1
	end
	return count
end

while true do
	execute()
end
