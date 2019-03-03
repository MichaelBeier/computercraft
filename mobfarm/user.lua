function run(config)
	local peripherals = setupPeripherals(config)
	local interface = createInterface(config, peripherals)
	local controllerCommunicator = createControllerCommunicator(config)
	local state = {
		selectionItems = {},
		jobs = {},
		page = 1,
		jobRequest = nil
	}

	interface.render(state)

	local jobTimer = os.startTimer(1)
	controllerCommunicator.sendDataRequest()

	while true do
		local eventType, arg1, arg2, arg3, arg4 = os.pullEvent()

		if eventType == "monitor_touch" then
			interface.handleMouseClick(state, eventType, arg1, arg2, arg3, arg4)
			interface.render(state)
		elseif eventType == "mob_click" then
			-- controllerCommunicator.sendJobRequest(arg1, "infinite")
			state.jobRequest = arg1
			interface.render(state)
		elseif eventType == "change_page" then
			state.page = arg1
			interface.render(state)
		elseif eventType == "monitor_resize" then
			interface.render(state)
		elseif eventType == "rednet_message" then
			if (controllerCommunicator.handleRednetMessage(state, arg1, arg3, arg2)) then
				interface.render(state)
			end
		elseif eventType == "timer" then
			if (jobTimer == arg1) then
				controllerCommunicator.sendDataRequest()
				jobTimer = os.startTimer(1)
			end
		end
	end
end

function createControllerCommunicator(config)
	local controllerId = rednet.lookup(config.protocols.createJob)

	if controllerId == nil then
		os.sleep(1)
		return createControllerCommunicator(config)
	end

	local sendMessage = function(protocol, content)
		return rednet.send(controllerId, content, protocol)
	end

	local sendDataRequest = function()
		sendMessage(config.protocols.getConfig)
		sendMessage(config.protocols.queryJobs)
	end

	local sendJobRequest = function(key, count)
		sendMessage(
			config.protocols.createJob,
			textutils.serialize(
				{
					priority = "user",
					count = 64,
					item = key
				}
			)
		)

		sendMessage(config.protocols.queryJobs)
	end

	local handleRednetMessage = function(state, senderId, protocol, message)
		if (senderId ~= controllerId or message == nil or protocol == "dns") then
			return false
		end

		local data = textutils.unserialize(message)

		if (protocol == config.protocols.queryJobs) then
			local newJobs = {}

			for i = 1, #data do
				local jobData = data[i]

				table.insert(
					newJobs,
					{
						name = jobData.displayName,
						id = jobData.mobID,
						requested = jobData.count,
						done = jobData.progress
					}
				)
			end

			state.jobs = newJobs

			return true
		end

		if (protocol == config.protocols.getConfig) then
			local newConfig = {}

			for i = 1, #data do
				local configEntry = data[i]

				table.insert(
					newConfig,
					{
						name = configEntry.displayName,
						id = configEntry.item,
						active = false
					}
				)
			end

			state.selectionItems = newConfig

			return true
		end

		return false
	end

	return {
		handleRednetMessage = handleRednetMessage,
		sendJobRequest = sendJobRequest,
		sendDataRequest = sendDataRequest
	}
end

function setupPeripherals(config)
	local selectorMonitor = peripheral.wrap(config.selectorMonitor)
	local loggerMonitor = peripheral.wrap(config.loggerMonitor)

	rednet.open("left")

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

	local render = function(state)
		term.redirect(selectorMonitor)
		selectionRenderer.render(state)
		term.redirect(loggerMonitor)
		loggerRenderer.render(state)
		term.redirect(term.native())
	end

	local handleMouseClick = function(state, eventType, side, x, y)
		if side == config.selectorMonitor then
			return selectionRenderer.handleMouseClick(state, x, y)
		elseif side == config.loggerMonitor then
			return loggerRenderer.handleMouseClick(state, x, y)
		end
	end

	return {
		render = render,
		handleMouseClick = handleMouseClick
	}
end

local headerHeight = 3
local footerHeight = 3

function createSelectionRenderer(monitor)
	local minListPadding = 1
	local buttonWidth = 16
	local buttonSpacing = 1
	local buttonHeight = 3
	local pageCount = 1
	local startPosX
	local buttonRenderer

	local renderHeader = function(state, sizeX)
		monitor.setCursorPos(1, 1)
		drawFilledBox(monitor, 1, 1, sizeX, 3, colors.white)
		monitor.setCursorPos(startPosX, 2)
		writeInColor(monitor, "Krasse Mobfarm", colors.lime, colors.white)
		monitor.setCursorPos(1, 1 + headerHeight)
	end

	local renderList = function(state, sizeX, sizeY)
		monitor.setCursorPos(1, headerHeight + 1)

		local longestName

		for i = 1, #state.selectionItems do
			if longestName == nil or string.len(state.selectionItems[i].name) > string.len(longestName) then
				longestName = state.selectionItems[i].name
			end
		end

		if longestName ~= nil then
			buttonWidth = string.len(longestName) + 2
		end

		local availableXSpace = sizeX
		local availableYSpace = sizeY - headerHeight - footerHeight

		local approxColCount = (availableXSpace - minListPadding * 2 + buttonSpacing) / (buttonSpacing + buttonWidth)
		local colCount = math.floor(approxColCount)

		local approxRowCount = (availableYSpace - minListPadding * 2 + buttonSpacing) / (buttonSpacing + buttonHeight)
		local rowCount = math.floor(approxRowCount)

		pageCount = math.ceil(#state.selectionItems / colCount / rowCount)

		local remainingXSpace = availableXSpace + buttonSpacing - (colCount * (buttonWidth + buttonSpacing))
		local remainingYSpace = availableYSpace + buttonSpacing - (rowCount * (buttonHeight + buttonSpacing))

		local _, listSpaceStartY = monitor.getCursorPos()
		local startPosY = listSpaceStartY + math.max(minListPadding, math.floor(remainingYSpace / 2))
		startPosX = 1 + math.max(minListPadding, math.floor(remainingXSpace / 2))

		advanceLines(monitor, minListPadding)

		local itemStartIndex = (state.page - 1) * pageCount

		for rowIndex = 1, rowCount do
			local _, yPos = monitor.getCursorPos()

			for colIndex = 1, colCount do
				local itemIndex = (rowIndex - 1) * colCount + colIndex + itemStartIndex
				local mob = state.selectionItems[itemIndex]

				if (mob == nil) then
					break
				end

				local colStartX = startPosX + (colIndex - 1) * (buttonWidth + buttonSpacing)

				buttonRenderer.createButton(
					{
						x = colStartX,
						y = yPos,
						width = buttonWidth,
						height = buttonHeight,
						text = mob.name,
						key = mob.name,
						color = colors.white,
						background = colors.lime
					}
				)
			end

			monitor.setCursorPos(1, yPos + buttonHeight + buttonSpacing)
		end
	end

	local renderFooter = function(state, sizeX, sizeY)
		local startPosY = sizeY - footerHeight + 1
		monitor.setCursorPos(1, startPosY)

		drawFilledBox(monitor, 1, startPosY, sizeX, startPosY + footerHeight, colors.white)

		local pageText = state.page .. " / " .. pageCount
		local textLen = string.len(pageText)

		local textStart = math.floor((sizeX - textLen) / 2)

		monitor.setCursorPos(textStart, startPosY + 1)
		writeInColor(monitor, pageText, colors.black, colors.white)

		if (state.page > 1) then
			buttonRenderer.createButton(
				{
					x = 2,
					y = startPosY,
					width = 8 + 2,
					height = 3,
					key = "previous",
					text = "Previous",
					colors = colors.black,
					background = colors.white
				}
			)
		end
		if (state.page < pageCount) then
			buttonRenderer.createButton(
				{
					x = sizeX - textLength - 2 - 1,
					y = startPosY,
					width = 4 + 2,
					height = 3,
					key = "next",
					background = colors.white,
					color = colors.black,
					text = "Next"
				}
			)
		end
	end

	local render = function(state)
		buttonRenderer = createButtonRenderer(monitor)
		monitor.setBackgroundColor(colors.black)
		monitor.clear()
		local sizeX, sizeY = monitor.getSize()

		renderList(state, sizeX, sizeY)
		renderHeader(state, sizeX)
		renderFooter(state, sizeX, sizeY)
	end

	local handleMouseClick = function(state, x, y)
		local buttonKey = buttonRenderer.findButton(x, y)

		if (buttonKey == nil) then
			return
		end

		if (buttonKey == "next") then
			os.queueEvent("change_page", math.min(state.page + 1, pageCount))
			return
		end

		if (buttonKey == "previous") then
			os.queueEvent("change_page", math.max(state.page - 1, 1))
			return
		end

		os.queueEvent("mob_click", buttonKey)
	end

	return {
		render = render,
		handleMouseClick = handleMouseClick
	}
end

function createLoggerRenderer(monitor)
	local buttons = {}
	local listEntryHeight = 1
	local minListPadding = 1
	local listEntrySpacing = 1

	local renderHeader = function(state, sizeX, sizeY)
		drawFilledBox(monitor, 1, 1, sizeX, headerHeight, colors.white)
		monitor.setCursorPos(2, 2)
		writeInColor(monitor, "Jobs", colors.green, colors.white)
	end

	local renderList = function(state, sizeX, sizeY)
		monitor.setCursorPos(1, headerHeight + 2)

		local availableYSpace = sizeY - headerHeight - footerHeight - minListPadding * 2

		local rowCount = math.floor(availableYSpace)

		local startY = headerHeight + 2

		for i = 1, #state.jobs do
			local job = state.jobs[i]

			local posY = startY + (i - 1) * (listEntryHeight + listEntrySpacing)

			monitor.setCursorPos(2, posY)
			writeInColor(monitor, job.name .. " [" .. job.done .. "/" .. job.requested .. "]", colors.white)
			advanceLines(monitor, 2)
		end
	end

	local renderFooter = function(state, sizeX, sizeY)
		local startPosY = sizeY - footerHeight + 1
		monitor.setCursorPos(1, startPosY)

		drawFilledBox(monitor, 1, startPosY, sizeX, footerHeight, colors.white)
	end

	local render = function(state)
		monitor.setBackgroundColor(colors.black)
		monitor.clear()
		local sizeX, sizeY = monitor.getSize()
		renderHeader(state, sizeX, sizeY)
		renderList(state, sizeX, sizeY)
		renderFooter(state, sizeX, sizeY)
	end

	local handleMouseClick = function(state, x, y)
		print("hi from logger monitor", "x", x, "y", y)
	end

	return {
		render = render,
		handleMouseClick = handleMouseClick
	}
end

function createButtonRenderer(monitor)
	local buttons

	local function createButton(button)
		local buttonColor = button.color ~= nil and button.color or colors.white
		local buttonBackground = button.background ~= nil and button.background or colors.black

		local endX = button.x + button.width - 1
		local endY = button.y + button.height - 1

		local maxTextWidth = button.width - 2
		local textLen = string.len(button.text)

		if (textLen > maxTextWidth) then
			textLen = maxTextWidth
			text = string.sub(text, 1, textLen)
		end

		local textStart = math.floor((maxTextWidth - textLen) / 2)

		monitor.setCursorPos(x, y)
		drawFilledBox(monitor, x, y, endX, endY, buttonBackground)
		monitor.setCursorPos(button.x + textStart, button.y + math.floor(button.height / 2))
		writeInColor(monitor, text, buttonColor, buttonBackground)

		table.insert(
			buttons,
			{
				startX = button.x,
				startY = button.y,
				endX = endX,
				endY = endY,
				key = key
			}
		)
	end

	local function findButton(x, y)
		for i = 1, #buttons do
			local button = buttons[i]

			if (x >= button.startX and x <= button.endX and y >= button.startY and y <= button.endY) then
				return button.key
			end
		end
		return nil
	end

	return {
		createButton = createButton,
		findButton = findButton
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

run(
	{
		selectorMonitor = "top",
		loggerMonitor = "monitor_0",
		hostName = "scheduler",
		protocols = {
			createJob = "newJob",
			queryJobs = "jobQuery",
			getConfig = "getConfig"
		}
	}
)
