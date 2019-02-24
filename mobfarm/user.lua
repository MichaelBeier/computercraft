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
		term.redirect(selectorMonitor)
		selectionRenderer.render(state)
		term.redirect(loggerMonitor)
		loggerRenderer.render(state)
		term.redirect(term.native())
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

		monitor.setBackgroundColor(colors.black)
		monitor.clear()
		monitor.setCursorPos(1, 1)
		drawFilledBox(monitor, 1, 1, sizeX, 3, colors.white)
		monitor.setCursorPos(1, 2)
		writeInColor(monitor, "Krasse Mobfarm", colors.lime, colors.white)
		monitor.setCursorPos(1, 4)
		writeInColor(monitor, "X", colors.white)
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

function writeInColor(output, text, color, backgroundColor)
	local originalColor = output.getTextColor()
	local originalBackgroundColor = output.getBackgroundColor()

	if (color ~= nil) then
		output.setTextColor(color)
	end

	if (backgroundColor ~= nil) then
		output.setBackgroundColor(backgroundColor)
	end

	output.write(text)
	output.setTextColor(originalColor)
	output.setBackgroundColor(originalBackgroundColor)
end

function drawFilledBox(output, startX, startY, endX, endY, colors)
	local originalBackground = output.getBackgroundColor()
	local originalTerminal = term.current()

	term.redirect(output)

	paintutils.drawFilledBox(startX, startY, endX, endY, colors)

	term.setBackgroundColor(originalBackground)
	term.redirect(originalTerminal)
end

run(
	{
		selectorMonitor = "top",
		loggerMonitor = "monitor_0"
	}
)
