function run(config)
	local peripherals = setupPeripherals(config)
	local interface = createInterface(config, peripherals)
	local state = {
		mobs = {
			{name = "Wither Skeleton", id = "wither", active = false}
		}
	}

	while true do
		local eventType, arg1, arg2, arg3, arg4 = os.pullEvent()

		if eventType == "mouse_click" then
			interface.handleMouseClick(eventType, arg1, arg2, arg3, arg4)
		end
		if eventType == "mob_click" then
		-- TODO: handle events which are being triggered by a click onto a mob on the monitor
		end

		interface.render()
	end
end

function setupPeripherals(config)
	local selectorMonitor = peripheral.wrap(config.selectorMonitor)
	local loggerMonitor = peripheral.wrap(config.loggerMonitor)

	return {
		selectorMonitor = selectorMonitor,
		loggerMonitor = loggerMonitor
	}
end

function createInterface(config, peripherals)
	local selectorMonitor = peripherals.selectorMonitor
	local loggerMonitor = peripherals.loggerMonitor

	function render(state)
		renderMobSelection(selectorMonitor, state)
		renderLogger(loggerMonitor, state)
	end

	function handleMouseClick(eventType, button, x, y)
		print("x", x, "y", y)
	end

	return {
		render = render,
		handleMouseClick = handleMouseClick
	}
end

function renderLogger(monitor, state)
end

function renderMobSelection(monitor, state)
end

run(
	{
		selectorMonitor = "top",
		loggerMonitor = "monitor_0"
	}
)
