function run(config)
	local peripherals = setupPeripherals(config)
	local interface = createInterface(config, peripherals)
	local state = {
		mobs = {
			{name = "Wither Skeleton", id = "wither", active = false}
		}
	}

	interface.render(state)

	while true do
		local eventType, arg1, arg2, arg3, arg4 = os.pullEvent()

		if eventType == "monitor_touch" then
			interface.handleMouseClick(eventType, arg1, arg2, arg3, arg4)
		end
		if eventType == "mob_click" then
		-- TODO: handle events which are being triggered by a click onto a mob on the monitor
		end

		interface.render(state)
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
		print("render")
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
		print("renderSelection")
		local sizeX, sizeY = monitor.getSize()

		monitor.setBackgroundColor(colors.black)
		monitor.clear()
		monitor.setCursorPos(0, 0)

		writeInColor(monitor, "Krasse Mobfarm", colors.lime)
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
		print("render logger")
	end

	function handleMouseClick(x, y)
		print("hi from logger monitor", "x", x, "y", y)
	end

	return {
		render = render,
		handleMouseClick = handleMouseClick
	}
end

function writeInColor(output, text, color)
	local originalColor = output.getTextColor()
	output.setTextColor(color)
	output.write(text)
	output.setTextColor(originalColor)
end

run(
	{
		selectorMonitor = "top",
		loggerMonitor = "monitor_0"
	}
)
