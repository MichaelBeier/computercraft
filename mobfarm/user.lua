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

		if eventType == "monitor_touch" then
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

	local selectionRenderer = createSelectionRenderer(selectorMonitor)
	local loggerRenderer = createLoggerRenderer(loggerMonitor)

	function render(state)
		selectionRenderer.render(state)
		loggerRenderer.render(state)
	end

	function handleMouseClick(eventType, side, x, y)
		if side == config.selectorMonitor then
			return selectionRenderer.handleMouseClick(x, y)
		elseif side == config.loggerMonitor then
			return loggerRenderer.handleMouseClick(x, y)
		end
	end

	return {
		render = render,
		handleMouseClick = handleMouseClick
	}
end

function createSelectionRenderer(monitor)
	local buttons

	function render(state)
		local sizeX, sizeY = monitor.getSize()

		monitor.setBackgroundColor(0x000000)
		monitor.clear()
		monitor.setCursorPos(0, 0)

		paintutils.drawBox(0, 0, sizeX, 3, 0xffffff)
		writeInColor(monitor, "Krasse Mobfarm", 0x00ff00)
	end

	function handleMouseClick(x, y)
		print("hi from selection monitor", "x", x, "y", y)
	end

	return {
		render = render,
		handleMouseClick = handleMouseClick
	}
end

function createLoggerRenderer(monitor)
	local buttons

	function render(state)
	end

	function handleMouseClick(x, y)
		print("hi from logger monitor", "x", x, "y", y)
	end

	return {
		render = render,
		handleMouseClick = handleMouseClick
	}
end

function writeInColor(term, text, color)
	local originalColor = term.getTextColor()
	term.setTextColor(color)
	term.write(text)
	term.setTextColor(originalColor)
end

run(
	{
		selectorMonitor = "top",
		loggerMonitor = "monitor_0"
	}
)
