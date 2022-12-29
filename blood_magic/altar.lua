local altar = peripheral.wrap("bloodmagic:altar_0")
local input = peripheral.wrap("minecraft:barrel_0")
local output = peripheral.wrap("refinedstorage:interface_0")

-- engimatica 6
local essenceRequirements = {
	-- other stone slate -> blank slate
	["occultism:otherstone_tablet"] = 1000,
	-- blank slate -> reinforced slate
	["bloodmagic:blankslate"] = 2000,
	-- reinforced slate -> imbued slate
	["bloodmagic:reinforcedslate"] = 5000,
	-- imbued slate -> demonic slate
	["bloodmagic:infusedslate"] = 15000,
	-- demonic slate -> etheral slate
	["bloodmagic:demonslate"] = 200000,
	-- firmament -> moonstone
	["kubejs:firmament"] = 7000,
	-- shadow steel -> master blood orb
	["create:shadow_steel"] = 80000
}

function execute()
	local tank = altar.tanks()[1]

	if tank == nil or tank.amount == 0 then
		-- no life essence available
		return
	end

	local essenceAvailable = tank.amount
	local processSlot
	local processCount
	local orbSlot
	local itemsWaitingForEssence = false

	for slot, details in pairs(input.list()) do
		if details.name == "bloodmagic:masterbloodorb" then
			orbSlot = slot
		else
			local requirement = essenceRequirements[details.name]

			if requirement == nil then
				print("processing " .. details.count .. " of " .. details.name .. " because it does not have defined requirements")
				processSlot = slot
				processCount = details.count
				break
			end

			processCount = math.min(math.floor(essenceAvailable / requirement), details.count)

			if processCount > 0 then
				processSlot = slot
				print("processing " .. processCount .. " of " .. details.name)
				break
			end

			itemsWaitingForEssence = true
		end
	end

	if processSlot == nil then
		if orbSlot ~= nil and not itemsWaitingForEssence then
			print("putting orb into altar for charging")
			input.pushItems(peripheral.getName(altar), orbSlot)
		end

		local activeAltarItem = altar.getItemDetail(1)

		if activeAltarItem ~= nil then
			if not (activeAltarItem.name == "bloodmagic:masterbloodorb" and not itemsWaitingForEssence) then
				print("detected an item inside altar. pulling it out")
				input.pullItems(peripheral.getName(altar), 1)
			end
		end

		print("no items detected or not enough essence available")

		os.sleep(4)
		return
	end

	local details = input.getItemDetail(processSlot)

	input.pushItems(peripheral.getName(altar), processSlot, processCount)

	while true do
		local altarDetails = altar.getItemDetail(1)

		if altarDetails.name ~= details.name then
			print("crafted " .. altarDetails.name)
			altar.pushItems(peripheral.getName(output), 1)
			break
		end
		os.sleep(1)
	end
end

while true do
	execute()
end
