function run(config)
	local peripherals = setupPeripherals(config)
	local interface = createInterface(config, peripherals)
	local state = {
		mobs = {
			{name = "Wither Skeleton", id = "wither", active = false},
			{name = "Wither Skeleton", id = "wither", active = false},
			{name = "Wither Skeleton", id = "wither", active = false},
			{name = "Wither Skeleton", id = "wither", active = false},
			{name = "Wither Skeleton", id = "wither", active = false},
			{name = "Wither Skeleton", id = "wither", active = false},
			{name = "Wither Skeleton", id = "wither", active = false},
			{name = "Wither Skeleton", id = "wither", active = false},
			{name = "Wither Skeleton", id = "wither", active = false},
			{name = "Wither Skeleton", id = "wither", active = false},
			{name = "Wither Skeleton", id = "wither", active = false},
			{name = "Wither Skeleton", id = "wither", active = false},
			{name = "Wither Skeleton", id = "wither", active = false},
			{name = "Wither Skeleton", id = "wither", active = false},
			{name = "Wither Skeleton", id = "wither", active = false},
			{name = "Wither Skeleton", id = "wither", active = false},
			{name = "Wither Skeleton", id = "wither", active = false},
			{name = "Wither Skeleton", id = "wither", active = false},
			{name = "Wither Skeleton", id = "wither", active = false},
			{name = "Wither Skeleton", id = "wither", active = false},
			{name = "Wither Skeleton", id = "wither", active = false},
			{name = "Wither Skeleton", id = "wither", active = false},
			{name = "Wither Skeleton", id = "wither", active = false},
			{name = "Wither Skeleton", id = "wither", active = false},
			{name = "Wither Skeleton", id = "wither", active = false},
			{name = "Wither Skeleton", id = "wither", active = false},
			{name = "Wither Skeleton", id = "wither", active = false},
			{name = "Wither Skeleton", id = "wither", active = false},
			{name = "Wither Skeleton", id = "wither", active = false},
			{name = "Wither Skeleton", id = "wither", active = false},
			{name = "Wither Skeleton", id = "wither", active = false},
			{name = "Wither Skeleton", id = "wither", active = false},
			{name = "Wither Skeleton", id = "wither", active = false},
			{name = "Wither Skeleton", id = "wither", active = false},
			{name = "Wither Skeleton", id = "wither", active = false},
			{name = "Wither Skeleton", id = "wither", active = false},
			{name = "Wither Skeleton", id = "wither", active = false},
			{name = "Wither Skeleton", id = "wither", active = false},
			{name = "Wither Skeleton", id = "wither", active = false},
			{name = "Wither Skeleton", id = "wither", active = false},
			{name = "Wither Skeleton", id = "wither", active = false},
			{name = "Wither Skeleton", id = "wither", active = false},
			{name = "Wither Skeleton", id = "wither", active = false},
			{name = "Wither Skeleton", id = "wither", active = false},
			{name = "Wither Skeleton", id = "wither", active = false},
			{name = "Wither Skeleton", id = "wither", active = false},
			{name = "Wither Skeleton", id = "wither", active = false},
			{name = "Wither Skeleton", id = "wither", active = false},
			{name = "Wither Skeleton", id = "wither", active = false},
			{name = "Wither Skeleton", id = "wither", active = false},
			{name = "Wither Skeleton", id = "wither", active = false},
			{name = "Wither Skeleton", id = "wither", active = false},
			{name = "Wither Skeleton", id = "wither", active = false},
			{name = "Wither Skeleton", id = "wither", active = false},
			{name = "Wither Skeleton", id = "wither", active = false},
			{name = "Wither Skeleton", id = "wither", active = false},
			{name = "Wither Skeleton", id = "wither", active = false},
			{name = "Wither Skeleton", id = "wither", active = false},
			{name = "Wither Skeleton", id = "wither", active = false},
			{name = "Wither Skeleton", id = "wither", active = false},
			{name = "Wither Skeleton", id = "wither", active = false},
			{name = "Wither Skeleton", id = "wither", active = false},
			{name = "Wither Skeleton", id = "wither", active = false},
			{name = "Wither Skeleton", id = "wither", active = false},
			{name = "Wither Skeleton", id = "wither", active = false},
			{name = "Wither Skeleton", id = "wither", active = false}
		},
		page = 1
	}

	interface.render(state)

	while true do
		local eventType, arg1, arg2, arg3, arg4 = os.pullEvent()

		if eventType == "monitor_touch" then
			interface.handleMouseClick(eventType, arg1, arg2, arg3, arg4)
		end
		if eventType == "mob_click" then
			print("mob click", arg1)
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
	local mobButtons = {}
	local headerHeight = 3
	local footerHeight = 3
	local minListPadding = 1
	local buttonWidth = 16
	local buttonSpacing = 1
	local buttonHeight = 3

	function render(state)
		monitor.setBackgroundColor(colors.black)
		monitor.clear()
		local sizeX, sizeY = monitor.getSize()

		renderList(state, sizeX, sizeY)
		renderHeader(state, sizeX)
	end

	function renderHeader(state, sizeX)
		monitor.setCursorPos(1, 1)
		drawFilledBox(monitor, 1, 1, sizeX, 3, colors.white)
		monitor.setCursorPos(1, 2)
		writeInColor(monitor, "Krasse Mobfarm", colors.lime, colors.white)
		monitor.setCursorPos(1, 1 + headerHeight)
	end

	function renderList(state, sizeX, sizeY)
		monitor.setCursorPos(1, headerHeight + 1)

		local longestName

		for i = 1, #state.mobs do
			if longestName == nil or string.len(state.mobs[i].name) > string.len(longestName) then
				longestName = state.mobs[i].name
			end
		end

		if longestName ~= nil then
			buttonWidth = string.len(longestName) + 2
		end

		local availableXSpace = sizeX
		local availableYSpace = sizeY - headerHeight - footerHeight

		local approxColCount = (availableXSpace + buttonSpacing) / (buttonSpacing + buttonWidth)
		local colCount = math.floor(approxColCount)

		local approxRowCount = (availableYSpace + buttonSpacing) / (buttonSpacing + buttonHeight)
		local rowCount = math.floor(approxRowCount)

		local pageCount = math.ceil(#state.mobs / colCount / rowCount)

		local remainingXSpace = availableXSpace + buttonSpacing - (colCount * (buttonWidth + buttonSpacing))
		local remainingYSpace = availableYSpace + buttonSpacing - (rowCount * (buttonHeight + buttonSpacing))

		local _, listSpaceStartY = monitor.getCursorPos()
		local startPosY = listSpaceStartY + math.max(minListPadding, math.floor(remainingYSpace / 2))
		local startPosX = math.max(minListPadding, math.floor(remainingXSpace / 2))

		advanceLines(monitor, minListPadding)

		for rowIndex = 1, rowCount do
			local _, yPos = monitor.getCursorPos()

			for colIndex = 1, colCount do
				local mob = state.mobs[(rowIndex - 1) * rowCount + colIndex]

				if (mob == nil) then
					break
				end

				local colStartX = startPosX + (colIndex - 1) * (buttonWidth + buttonSpacing)

				local text = string.sub(mob.name, 1, buttonWidth - 2)
				local textLength = string.len(text)

				local textStart = math.floor((buttonWidth - textLength) / 2)

				local endX = colStartX + buttonWidth - 1
				local endY = yPos + buttonHeight - 1

				monitor.setCursorPos(colStartX, yPos)
				drawFilledBox(monitor, colStartX, yPos, endX, endY, colors.lime)
				monitor.setCursorPos(colStartX + textStart, yPos + math.floor(buttonHeight / 2))
				writeInColor(monitor, text, colors.white, colors.lime)

				table.insert(
					mobButtons,
					{
						startX = colStartX,
						startY = yPos,
						endX = endX,
						endY = endY,
						key = mob.id
					}
				)
			end

			monitor.setCursorPos(1, yPos + buttonHeight + buttonSpacing)
		end
	end

	function handleMouseClick(x, y)
		local mob = findButton(mobButtons, x, y)

		if (mob == nil) then
			return
		end

		os.queueEvent("mob_click", mob)
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
	local originalX, originalY = output.getCursorPos()

	term.redirect(output)

	paintutils.drawFilledBox(startX, startY, endX, endY, colors)

	term.setBackgroundColor(originalBackground)
	term.redirect(originalTerminal)
	originalTerminal.setCursorPos(originalX, originalY)
end

function advanceLines(monitor, count)
	local _, y = monitor.getCursorPos()
	monitor.setCursorPos(1, y + count)
end

function findButton(buttons, x, y)
	for i = 1, #buttons do
		local button = buttons[i]

		if (x >= button.startX and x <= button.endX and y >= button.startY and y <= button.endY) then
			return button.key
		end
	end
	return nil
end

run(
	{
		selectorMonitor = "top",
		loggerMonitor = "monitor_0"
	}
)
