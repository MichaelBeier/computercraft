local configName = "startupConfig"

function getConfig()
	if not fs.exists(configName) then
		return nil
	end

	local configHandle = fs.open(configName, "r")
	local configContent = configHandle.readAll()
	local config = textutils.unserialize(configContent)

	return config
end

function createConfig()
	print("Script-Url:")
	local url = io.read()

	local content = download(url)

	if (content == nil) then
		print("No valid content found for provided url")
		return createConfig()
	end

	local configHandle = fs.open(configName, "w")
	local config = {
		url,
		outputPath = "program.lua"
	}

	configHandle.write(textutils.serialize(config))
	return config
end

function download(url)
	local httpResponse = http.get(config.url)

	local statusCode = httpResponse.getResponseCode()

	if statusCode ~= 200 then
		return nil
	end

	local scriptContent = httpResponse.readAll()
	return scriptContent
end

function downloadAndExecute(config)
	local scriptContent = download(config.url)

	if scriptContent == nil then
		print("Could not load script content. Please make sure the url is correct")
		return
	end

	local fileHandle = fs.open(config.outputPath, "w")
	fileHandle.write(scriptContent)
	fileHandle.flush()
	fileHandle.close()

	shell.run(config.outputPath)
end

function run()
	local config = getConfig()

	if (config == nil) then
		config = createConfig()
	end

	downloadAndExecute(config)
end

run()
