local altar = peripheral.wrap("bloodmagic:altar_0")
local input = peripheral.wrap("minecraft:barrel_0")
local output = peripheral.wrap("refinedstorage:interface_0")

function execute()
	local filledSlot = getFirstFilledSlot()

	if filledSlot == nil then
		os.sleep(2)
		return
	end

	local details = input.getItemDetail(filledSlot)

	input.pushItems(peripheral.getName(altar), filledSlot)

	while true do
		local altarDetails = altar.getItemDetail(1)

		if altarDetails.name ~= details.name then
			altar.pushItems(peripheral.getName(output), 1)
			break
		end
		os.sleep(1)
	end
end

function getFirstFilledSlot()
	local items = input.list()

	for key, _ in pairs(items) do
		return key
	end
end

while true do
	execute()
end
