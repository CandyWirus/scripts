--Andy_Wirus#5999 for issues
--https://raw.githubusercontent.com/CandyWirus/scripts/master/TeleportUtility.lua

assert(RenderWindow, "no v3?? kys queuetard")

local module = shared.TeleportUtility or {}
shared.TeleportUtility = module

local TeleportService = cloneref(game:GetService("TeleportService"))
local HttpService = cloneref(game:GetService("HttpService"))
local AssetService = cloneref(game:GetService("AssetService"))
local Players = cloneref(game:GetService("Players"))
local GuiService = cloneref(game:GetService("GuiService"))
local Stats = cloneref(game:GetService("Stats"))

local rw = RenderWindow.new("Teleport Utility")
local tabs = rw:TabMenu()

local generalTab = tabs:Add("General")
local uvTab = tabs:Add("Universe Viewer")

local placeId = game.PlaceId
if placeId == 0 then
	game:GetPropertyChangedSignal("PlaceId"):Wait()
	placeId = game.PlaceId
end
local gameId = game.GameId
if gameId == 0 then --autoexecute
	game:GetPropertyChangedSignal("GameId"):Wait()
	gameId = game.GameId
end
local jobId = game.JobId
if jobId == "" then
	game:GetPropertyChangedSignal("JobId"):Wait()
	jobId = game.Jobid
end

local fileName = "TeleportUtility.json"
local scriptSettings = {}
if isfile(fileName) then
	local valid, value = pcall(function()
		return HttpService:JSONDecode(readfile(fileName))
	end)
	if valid then
		scriptSettings = value
	end
end

local autoReconnectCheck
local showTimeoutCheck
local serverTPCheck
local clientTPCheck
local rejoin

local save = function()
    if autoReconnectCheck and showTimeoutCheck and serverTPCheck and clientTPCheck then
        writefile(fileName, HttpService:JSONEncode({
            autoreconnect = autoReconnectCheck.Value,
            timeout = showTimeoutCheck.Value,
            disableServerTP = not serverTPCheck.Value,
            disableClientTP = not clientTPCheck.Value
        }))
        return true
    end
    return false
end

--general

local parseJoinString = function(joinString)
	local index = string.find(joinString, ":")
	if index then
		return tonumber(string.sub(joinString, 1, index - 1)), string.sub(joinString, index + 1, -1)
	else
		return nil
	end
end

local notify = function(message, toastType)
	print("[Teleport Utility] " .. tostring(message))
	syn.toast_notification({
		Type = toastType or 4,
		Title = "Teleport Utility",
		Content = message
	})
end

local printTeleport = function(place, job)
	local str = "Teleporting to " .. place
	if job then
		str ..= ":" .. job
	end
	notify(str .. "...", 4)
end

local tpFunc = [[
	local Players = cloneref(game:GetService("Players"))
	local TeleportService = cloneref(game:GetService("TeleportService"))

	local placeId = %s
	local jobId = "%s"
	
	local module = shared.TeleportUtility or {}
	shared.TeleportUtility = module
	module.AutoReconnectRestricted = true
	
	print("[Teleport Utility] Teleporting to " .. placeId .. ":" .. jobId .. "...")
	syn.toast_notification({
		Type = 4,
		Title = "Teleport Utility",
		Content = "Teleporting to " .. placeId .. ":" .. jobId .. "..."
	})
	TeleportService:TeleportToPlaceInstance(placeId, jobId)
	local player = Players.LocalPlayer or Players.PlayerAdded:Wait()
	player:Kick()
]]
local joblessFunc = [[
	local Players = cloneref(game:GetService("Players"))
	local TeleportService = cloneref(game:GetService("TeleportService"))

	local placeId = %s
	
	local module = shared.TeleportUtility or {}
	shared.TeleportUtility = module
	module.AutoReconnectRestricted = true
	
	print("[Teleport Utility] Teleporting to " .. placeId .. "...")
	syn.toast_notification({
		Type = 4,
		Title = "Teleport Utility",
		Content = "Teleporting to " .. placeId .. "..."
	})
	TeleportService:Teleport(placeId)
	local player = Players.LocalPlayer or Players.PlayerAdded:Wait()
	player:Kick()
]]
local forceTeleport = function(place, job) --bypasses third party teleport restrictions, which should be a built-in feature to synapse imo
	--syn.queue_on_teleport(string.format(if job then tpFunc else joblessFunc, place, job)) --method is broken https://sx3.nolt.io/2142
	--rejoin(placeId)
	notify("Force-Teleport is temporarily disabled", 3)
end

local boxLine = generalTab:SameLine()

local serverHopButton = boxLine:Button()
serverHopButton.Label = "Server Hop"

local tpButton = boxLine:Button()
tpButton.Label = "Teleport"

serverHopButton.OnUpdated:Connect(function()
	notify("Finding server to hop to...", 4)
	local success, servers = pcall(function()
		return HttpService:JSONDecode(syn.request({
			Url = "https://games.roblox.com/v1/games/" .. tostring(placeId) .. "/servers/Public?limit=100",
			Method = "GET"
		}).Body).data
	end)
	if not success then
		return
	end
	local job
	while true do
		if #servers > 0 then
			local index = math.random(1, #servers)
			local server = servers[index]
			job = server.id
			if server.playing < server.maxPlayers and job ~= jobId then
				break
			else
				table.remove(servers, index)
			end
		else
			job = nil
			break
		end
	end
	if job then
		rejoin(placeId, job)
	else
		rejoin(placeId)
	end
end)

local box = boxLine:TextBox()
generalTab:Label("Supports join strings, Place ID's, and Job ID's")
generalTab:Separator()

clientTPCheck = generalTab:CheckBox()
serverTPCheck = generalTab:CheckBox()

clientTPCheck.Label = "Allow Client-side Teleports"
serverTPCheck.Label = "Allow Server-side Teleports"
clientTPCheck.Value = not scriptSettings.disableClientTP
serverTPCheck.Value = not scriptSettings.disableServerTP

local serverTeleportConnection

local serverTpToggle = function(activated)
	if serverTeleportConnection then
		if activated then
			serverTeleportConnection:Enable()
		else
			serverTeleportConnection:Disable()
		end
	else
		serverTPCheck.Value = true
	end
	save()
end

clientTPCheck.OnUpdated:Connect(save)


task.spawn(function()
	local player = Players.LocalPlayer or Players.PlayerAdded:Wait()
	if not game:IsLoaded() then
		game.Loaded:Wait()
	end
	serverTeleportConnection = getconnections(player.OnTeleportInternal)[1]
	serverTpToggle(not scriptSettings.disableServerTP)
end)


serverTPCheck.OnUpdated:Connect(serverTpToggle)

local oldnamecall
oldnamecall = hookfunction(getrawmetatable(game).__namecall, function(...)
	if clientTPCheck.Value then
		return oldnamecall(...)
	end
end, AllFilter.new({
	ArgumentFilter.new(1, TeleportService),
	AnyFilter.new({
		NamecallFilter.new("Teleport"),
		NamecallFilter.new("TeleportToPlaceInstance"),
		NamecallFilter.new("TeleportToPrivateServer"),
		NamecallFilter.new("TeleportToSpawnByname"),
	}),
	CallerFilter.new(true)
}))

generalTab:Separator()

autoReconnectCheck = generalTab:CheckBox()
showTimeoutCheck = generalTab:CheckBox()

autoReconnectCheck.Label = "Auto Reconnect"
showTimeoutCheck.Label = "Display connection time-outs"
autoReconnectCheck.Value = not not scriptSettings.autoreconnect
showTimeoutCheck.Value = not not scriptSettings.timeout

local ConnectionError = Enum.ConnectionError
local TeleportResult = Enum.TeleportResult
local errorEnums = {
	Retry = {
		ConnectionError.TeleportErrors,
		ConnectionError.TeleportFailure,
		ConnectionError.TeleportFlooded,
		ConnectionError.DisconnectDuplicatePlayer,
		ConnectionError.DisconnectConnectionLost,
		ConnectionError.DisconnectReceivePacketError,
		TeleportResult.Failure,
		TeleportResult.Flooded
	},
	Cancel = {
		ConnectionError.DisconnectWrongVersion,
		ConnectionError.DisconnectModeratedGame,
		TeleportResult.GameNotFound,
		TeleportResult.Unauthorized
	},
	Jobless = {
		ConnectionError.TeleportGameEnded,
		ConnectionError.TeleportUnauthorized,
		ConnectionError.TeleportGameFull,
		ConnectionError.DisconnectRobloxMaintenance,
		ConnectionError.PlacelaunchRestricted,
		ConnectionError.DisconnectLuaKick,
		ConnectionError.PlacelaunchGameEnded,
		ConnectionError.DisconnectDevMaintenance,
		ConnectionError.DisconnectClientRequest,
		ConnectionError.DisconnectRaknetErrors,
		TeleportResult.GameEnded,
		TeleportResult.GameFull
	}
}

rejoin = function(place, job)
	module.AutoReconnectRestricted = true
	local thread = coroutine.running()
	local connection
	connection = TeleportService.TeleportInitFailed:Connect(function(player, result)
		TeleportService:TeleportCancel()
		notify("Teleport failed with \"" .. tostring(result) .. "\"", 3)
		for _, v in pairs(errorEnums.Retry) do
			if v == result then
				printTeleport(place, job)
				if job then
					TeleportService:TeleportToPlaceInstance(place, job)
				else
					TeleportService:Teleport(place)
				end
			end
		end
		for _, v in pairs(errorEnums.Cancel) do
			if v == result then
				connection:Disconnect()
				return assert(coroutine.resume(thread, false))
			end
		end
		for _, v in pairs(errorEnums.Jobless) do
			if v == result then
				job = nil
				printTeleport(place, job)
				TeleportService:Teleport(place)
			end
		end
	end)
	TeleportService:TeleportCancel()
	printTeleport(place, job)
	if job then
		TeleportService:TeleportToPlaceInstance(place, job)
	else
		TeleportService:Teleport(place)
	end
	return coroutine.yield()
end

tpButton.OnUpdated:Connect(function()
	local value = box.Value
	local jsPlaceId, job = parseJoinString(value)
	if jsPlaceId then
		forceTeleport(jsPlaceId, job)
	else
		local actualPlaceId = tonumber(value)
		if actualPlaceId then
			forceTeleport(actualPlaceId)
		elseif #value == 36 then
			rejoin(placeId, value)
		else
			rejoin(placeId, jobId)
		end
	end
end)

autoReconnectCheck.OnUpdated:Connect(save)
showTimeoutCheck.OnUpdated:Connect(save)

--autoreconnect

local teleportCheck = function()
	if autoReconnectCheck.Value and not module.AutoReconnectRestricted then
		local errorCode = GuiService:GetErrorCode()
		for _, v in pairs(errorEnums.Retry) do
			if v == errorCode then
				return rejoin(placeId, jobId)
			end
		end
		for _, v in pairs(errorEnums.Cancel) do
			if v == errorCode then
				game:Shutdown()
			end
		end
		for _, v in pairs(errorEnums.Jobless) do
			if v == errorCode then
				return rejoin(placeId)
			end
		end
	end
end

local box = PolyLineDynamic.new({
	Point2D.new(0, 0, .3, 0),
	Point2D.new(1, 0, .3, 0),
	Point2D.new(1, 0, .35, 0),
	Point2D.new(0, 0, .35, 0)
})
box.Color = Color3.fromRGB(51, 51, 51)
box.Opacity = .8
box.FillType = 2

local text = TextDynamic.new(Point2D.new(.5, 0, .325, 0))
text.Size = 80
text.Color = Color3.fromRGB(241, 241, 241)
text.Font = DrawFont.RegisterDefault("Inconsolata_Regular", {
	PixelSize = 120,
	UseStb = false,
	Scale = true,
	Bold = false
})

box.Visible = false
text.Visible = false

task.spawn(function()
	local teleporting = false
	while task.wait() do --autoexecute shit
		teleportCheck()
		if game:IsLoaded() then
			break
		end
	end

	local lastKbps
	local lastTime = tick()
	local downTime = 0
	while task.wait(.03) do
		local delta = tick() - lastTime
		local new = Stats.DataReceiveKbps
		if new == lastKbps then
			if GuiService:GetErrorCode() == Enum.ConnectionError.OK then
				downTime += delta
				if downTime >= 1 then
					text.Text = "Server not responding... " .. string.format("%0.2f", downTime)
					box.Visible = showTimeoutCheck.Value
					text.Visible = showTimeoutCheck.Value
				else
					box.Visible = false
					text.Visible = false
				end
			else
				teleportCheck()
			end
		else
			downTime = 0
			box.Visible = false
			text.Visible = false
		end
		lastKbps = new
		lastTime = tick()
	end
end)

--universe viewer (yields)

local activeEntry = {}
local addPlace = function(data)
	local selectable = uvTab:Selectable()
	local line = uvTab:SameLine()
	local separator = uvTab:Separator()
	local tpButton = line:Button()
	local copyButton = line:Button()
	
	local id = data.PlaceId
	
	selectable.Toggles = true
	line.Visible = false
	separator.Visible = false
	
	local gameName = data.Name
	selectable.Label = gameName .. (id == placeId and " - you are HERE" or "")
	tpButton.Label = "Teleport"
	copyButton.Label = "Copy ID"
	
	local toggle = false
	selectable.OnUpdated:Connect(function()
		if activeEntry[1] == selectable or activeEntry[1] == nil then
			toggle = not toggle
			selectable.Value = toggle
			line.Visible = toggle
			separator.Visible = toggle
		elseif activeEntry[1] then
			toggle = true
			activeEntry[1].Value = false
			activeEntry[2].Visible = false
			activeEntry[3].Visible = false
			selectable.Value = true
			line.Visible = true
			separator.Visible = true
		end
		activeEntry[1] = selectable
		activeEntry[2] = line
		activeEntry[3] = separator
	end)
	tpButton.OnUpdated:Connect(function()
		rejoin(id)
	end)
	copyButton.OnUpdated:Connect(function()
		local strid = tostring(id)
		notify(string.format("Copied %s (%s) to clipboard", strid, gameName), 1)
		setclipboard(strid)
	end)
end

local url = "https://develop.roblox.com/v1/universes/" .. gameId

while true do
	local success = pcall(function()
		local data = HttpService:JSONDecode(game:HttpGet(url))
		local name = data.name
		local starterId = data.rootPlaceId
		local line = uvTab:SameLine()
		
		local tpButton = line:Button()
		local copyButton = line:Button()
		line:Label(name)
		copyButton.Label = "Copy Game ID"
		copyButton.OnUpdated:Connect(function()
			local strid = tostring(gameId)
			notify(string.format("Copied %s (%s) to clipboard", strid, name), 1)
			setclipboard(strid)
		end)
		
		tpButton.Label = "Teleport to Start Place"
		tpButton.OnUpdated:Connect(function()
			rejoin(starterId)
		end)
		uvTab:Separator()
	end)
	if success then
		break
	end
end

local pages = AssetService:GetGamePlacesAsync()

while true do
	for _, v in pairs(pages:GetCurrentPage()) do
		addPlace(v)
	end
	if pages.IsFinished then
		break
	end
	pages:AdvanceToNextPageAsync()
end

module.RenderWindow = rw
