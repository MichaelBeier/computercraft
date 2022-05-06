local input = peripheral.wrap("minecraft:barrel_1")
local craftChest = peripheral.wrap("minecraft:barrel_2")

local crafterDirection = "right"
local vacuumDirection = "back"
local dispenserDirection = "left"

function execute()
	local slotsUsed = tableLength(input.list())

	print("waiting for items")

	if slotsUsed == 0 then
		os.sleep(2)
		return
	end

	print("blocking crafter")
	redstone.setAnalogOutput(crafterDirection, 15)

	print("loading inventory with chute")

	for slot, _ in pairs(input.list()) do
		input.pushItems(peripheral.getName(craftChest), slot)
	end

	print("unblocking crafter")
	redstone.setAnalogOutput(crafterDirection, 0)

	print("waiting for chute to do its thing")
	os.sleep(slotsUsed * 2)

	print("shooting the arrow")
	redstone.setAnalogOutput(dispenserDirection, 15)

	print("waiting for lightning")
	os.sleep(2)

	redstone.setAnalogOutput(dispenserDirection, 0)

	print("enabling vacuum")
	redstone.setAnalogOutput(vacuumDirection, 15)
	os.sleep(slotsUsed * 2)

	print("disabling vacuum")
	redstone.setAnalogOutput(vacuumDirection, 0)
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
