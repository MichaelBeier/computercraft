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
			state.jobRequest = {
				id = arg1,
				count = 1
			}
			interface.render(state)
		elseif eventType == "job_request_set_count" then
			state.jobRequest.count = arg1
			interface.render(state)
		elseif eventType == "job_request_cancel" then
			state.jobRequest = nil
			interface.render(state)
		elseif eventType == "job_request_send" then
			controllerCommunicator.sendJobRequest(state.jobRequest.id, state.jobRequest.count)
			state.jobRequest = nil
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
					count = count,
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
	local jobStartRenderer = createJobStartRenderer(selectorMonitor)
	local loggerRenderer = createLoggerRenderer(loggerMonitor)

	local render = function(state)
		term.redirect(selectorMonitor)
		if (state.jobRequest == nil) then
			selectionRenderer.render(state)
		else
			jobStartRenderer.render(state)
		end
		term.redirect(loggerMonitor)
		loggerRenderer.render(state)
		term.redirect(term.native())
	end

	local handleMouseClick = function(state, eventType, side, x, y)
		if side == config.selectorMonitor then
			if (state.jobRequest ~= nil) then
				return jobStartRenderer.handleMouseClick(state, x, y)
			end

			return selectionRenderer.handleMouseClick(state, x, y)
		end
		if side == config.loggerMonitor then
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
	local displayBuffer = createDisplayBuffer(monitor)

	local renderHeader = function(monitor, state, sizeX)
		monitor.setCursorPos(1, 1)
		drawFilledBox(monitor, 1, 1, sizeX, 3, colors.white)
		monitor.setCursorPos(startPosX, 2)
		writeInColor(monitor, "Krasse Mobfarm", colors.lime, colors.white)
		monitor.setCursorPos(1, 1 + headerHeight)
	end

	local renderList = function(monitor, state, sizeX, sizeY)
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
						key = mob.id,
						color = colors.white,
						background = colors.lime
					}
				)
			end

			monitor.setCursorPos(1, yPos + buttonHeight + buttonSpacing)
		end
	end

	local renderFooter = function(monitor, state, sizeX, sizeY)
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
		local nextWindow = displayBuffer.next()
		buttonRenderer = createButtonRenderer(nextWindow)

		local sizeX, sizeY = nextWindow.getSize()

		renderList(nextWindow, state, sizeX, sizeY)
		renderHeader(nextWindow, state, sizeX)
		renderFooter(nextWindow, state, sizeX, sizeY)

		displayBuffer.swap()
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

function createJobStartRenderer(monitor)
	local buttonRenderer

	local function renderHeader(state, sizeX, sizeY)
		drawFilledBox(monitor, 1, 1, sizeX, headerHeight, colors.white)
		monitor.setCursorPos(2, 2)
		writeInColor(monitor, "Please select an amount", colors.green, colors.white)

		buttonRenderer.createButton(
			{
				x = sizeX - 6,
				y = 1,
				width = 6,
				height = 3,
				text = "Back",
				key = "back",
				color = colors.black,
				background = colors.white
			}
		)
	end

	local function renderContent(state, sizeX, sizeY)
		local selectedItem =
			findInArray(
			state.selectionItems,
			function(item)
				return item.id == state.jobRequest.id
			end
		)

		monitor.setCursorPos(2, headerHeight + 2)
		writeInColor(monitor, "Selected mob: ", colors.white, colors.black)
		writeInColor(monitor, selectedItem.name, colors.green, colors.black)

		local remainingSizeY = sizeY - headerHeight - 2 - footerHeight - 2 - 2

		local posY = headerHeight + 4 + math.floor((remainingSizeY - 3) / 2)
		local posX = math.floor((sizeX - (5 * 7) - 1) / 2)

		local x = posX

		buttonRenderer.createButton(
			{
				x = x,
				y = posY,
				height = 3,
				width = 6,
				color = colors.white,
				background = colors.lime,
				text = "-10",
				key = -10
			}
		)

		x = x + 7

		buttonRenderer.createButton(
			{
				x = x,
				y = posY,
				height = 3,
				width = 6,
				color = colors.white,
				background = colors.lime,
				text = "-1",
				key = -1
			}
		)

		x = x + 7

		buttonRenderer.createButton(
			{
				x = x,
				y = posY,
				height = 3,
				width = 6,
				color = colors.white,
				background = colors.black,
				text = state.jobRequest.count,
				key = "count"
			}
		)

		x = x + 7

		buttonRenderer.createButton(
			{
				x = x,
				y = posY,
				height = 3,
				width = 6,
				color = colors.white,
				background = colors.lime,
				text = "+1",
				key = 1
			}
		)

		x = x + 7

		buttonRenderer.createButton(
			{
				x = x,
				y = posY,
				height = 3,
				width = 6,
				color = colors.white,
				background = colors.lime,
				text = "+10",
				key = 10
			}
		)

		buttonRenderer.createButton(
			{
				x = posX,
				y = posY + 4,
				height = 3,
				width = x - posX + 6,
				color = colors.white,
				background = colors.red,
				text = "start",
				key = "start"
			}
		)
	end

	local function render(state)
		monitor.setBackgroundColor(colors.black)
		monitor.clear()
		local sizeX, sizeY = monitor.getSize()
		buttonRenderer = createButtonRenderer(monitor)

		renderHeader(state, sizeX, sizeY)
		renderContent(state, sizeX, sizeY)
	end

	local function handleMouseClick(state, x, y)
		local clickedButton = buttonRenderer.findButton(x, y)

		if (clickedButton == nil) then
			return
		end

		if (clickedButton == "back") then
			os.queueEvent("job_request_cancel")
			return
		end

		if (clickedButton == "count") then
			return
		end

		if (clickedButton == "start") then
			return os.queueEvent("job_request_send")
		end

		os.queueEvent("job_request_set_count", math.max(state.jobRequest.count + clickedButton, 0))
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
	local buttons = {}

	local function createButton(button)
		local buttonColor = button.color ~= nil and button.color or colors.white
		local buttonBackground = button.background ~= nil and button.background or colors.black

		local endX = button.x + button.width - 1
		local endY = button.y + button.height - 1

		local maxTextWidth = button.width - 2
		local text = button.text
		local textLen = string.len(text)

		if (textLen > maxTextWidth) then
			textLen = maxTextWidth
			text = string.sub(text, 1, textLen)
		end

		local textStart = math.floor((button.width - textLen) / 2)

		monitor.setCursorPos(button.x, button.y)
		drawFilledBox(monitor, button.x, button.y, endX, endY, buttonBackground)
		monitor.setCursorPos(button.x + textStart, button.y + math.floor(button.height / 2))
		writeInColor(monitor, text, buttonColor, buttonBackground)

		table.insert(
			buttons,
			{
				startX = button.x,
				startY = button.y,
				endX = endX,
				endY = endY,
				key = button.key
			}
		)
	end

	local function findButton(x, y)
		local clickedButton =
			findInArray(
			buttons,
			function(button)
				return x >= button.startX and x <= button.endX and y >= button.startY and y <= button.endY
			end
		)

		if (clickedButton ~= nil) then
			return clickedButton.key
		end

		return nil
	end

	return {
		createButton = createButton,
		findButton = findButton
	}
end

function createDisplayBuffer(monitor)
	local currentWindow = nil
	local nextWindow = nil

	local function next()
		local sizeX, sizeY = monitor.getSize()
		nextWindow = window.create(monitor, 1, 1, sizeX, sizeY, false)
		return nextWindow
	end

	local function swap()
		if (currentWindow ~= nil) then
			currentWindow.setVisible(false)
		end
		nextWindow.setVisible(true)
		nextWindow.redraw()
		currentWindow = nextWindow
	end

	return {
		next = next,
		swap = swap
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

function printDebug(...)
	local originalTerminal = term.current()
	term.redirect(term.native())
	print(...)
	term.redirect(originalTerminal)
end

function findInArray(haystack, fn)
	for i = 1, #haystack do
		local item = haystack[i]

		if (fn(item)) then
			return item
		end
	end

	return nil
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
