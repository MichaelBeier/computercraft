local peripherals = peripheral.getNames()
local monitor
local reactor
local turbines = {}
local capabank = peripheral.wrap("top")
local selected = ""
local userOff = false

for x = 1, #peripherals do
	if (peripheral.getType(peripherals[x]) == "monitor") then
		monitor = peripheral.wrap(peripherals[x])
	elseif (peripheral.getType(peripherals[x]) == "BigReactors-Reactor") then
		reactor = peripheral.wrap(peripherals[x])
	elseif (peripheral.getType(peripherals[x]) == "BigReactors-Turbine") then
		table.insert(turbines, peripherals[x])
	end
end

monitor.setTextScale(1)
local sizex, sizey = monitor.getSize()

local contentwindow

function toggleReactor()
	gui.toggleButton("Reactor")
	reactor.setActive(not reactor.getActive())
end

function renderTurbine(turbinename)
	gui.toggleButton(turbinename)
	peripheralside = ""

	for x = 1, #turbines do
		if (string.find(turbines[x], turbinename)) then
			peripheralside = turbines[x]
		end
	end
	turbine = peripheral.wrap(peripheralside)
	term.write(peripheralside)
	turbine.setActive(not turbine.getActive())
end

function updateDynamicUI()
	energyoutput = 0

	energyoutput = energyoutput + reactor.getEnergyProducedLastTick()

	for x = 1, #turbines do
		turbine = peripheral.wrap(turbines[x])
		energyoutput = energyoutput + turbine.getEnergyProducedLastTick()
	end
	energyoutput = math.floor(energyoutput / 100) / 10
	gui.label(1, 1, "Energyproduction: " .. energyoutput .. "KRF/t")
	gui.label(2, 8, tostring(reactor.getControlRodLevel(1)))
end

function createStaticUI()
	--monitor.clear()
	monitor.setCursorPos(1, 1)
	gui.addButton("Reactor", toggleReactor, 2, 10, sizey - 3, sizey - 1, colors.green, colors.red)
	currentx = 12
	for x = 1, #turbines do
		gui.addButton("Turbine_" .. x - 1, Turbine1, currentx, currentx + 10, sizey - 3, sizey - 1, colors.green, colors.red)
		currentx = currentx + 12
	end
	gui.addButton("+10", x, 2, 6, 4, 6, colors.green, colors.red)
	gui.addButton("-10", x, 2, 6, 10, 12, colors.green, colors.red)
	gui.screenButton()
end

local maxStorage = 10000000
local lastPercentage

function manageReactor()
	local stored = reactor.getEnergyStored()
	local storedPercentage = 100 / maxStorage * stored

	if lastPercentage == nil then
		lastPercentage = storedPercentage
	end

	local percentageDiff = storedPercentage - lastPercentage

	if storedPercentage < 5 then
		reactor.setActive(true)
	end

	if storedPercentage > 80 then
		reactor.setActive(false)
	end
end

function loadApis()
	if (fs.exists("apis/gui") == false) then
		shell.run("pastebin", "get", "r3WxheVA", "apis/gui")
	end
	if (fs.exists("apis/settingapi") == false) then
		shell.run("pastebin", "get", "CwZuW9LE", "apis/settingapi")
	end
	os.loadAPI("apis/gui")
	os.loadAPI("apis/settingapi")
end

function startup()
	term.clear()
	term.setCursorPos(1, 1)
	term.write("NextGen NuclearControl")
	loadApis()
	createStaticUI()
	updateDynamicUI()
end

monitor.clear()

startup()

while true do
	os.startTimer(2)
	local event, arg1, arg2, arg3 = os.pullEvent()
	if (event == "timer") then
		manageReactor()
		updateDynamicUI()
	elseif (event == "monitor_touch") then
		button = gui.checkxy(arg2, arg3)
		if (type(button) ~= "boolean") then
			if (button == "Reactor") then
				toggleReactor()
			elseif (string.find(button, "Turbine")) then
				renderTurbine(button)
			elseif (button == "+10") then
				reactor.setAllControlRodLevels(reactor.getControlRodLevel(1) + 10)
			elseif (button == "-10") then
				reactor.setAllControlRodLevels(reactor.getControlRodLevel(1) - 10)
			end
		end
	end
	createStaticUI()
end
