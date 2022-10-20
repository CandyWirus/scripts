--Andy_Wirus#5999 for issues
--https://raw.githubusercontent.com/CandyWirus/scripts/master/TeleportUtility.lua

assert(RenderWindow, "no v3?? kys queuetard")

local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local GuiService = game:GetService("GuiService")
local Stats = game:GetService("Stats")

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

--general

local parseJoinString = function(joinString)
	local index = string.find(joinString, ":")
	if index then
		return tonumber(string.sub(joinString, 1, index - 1)), string.sub(joinString, index + 1, -1)
	else
		return nil
	end
end

local tpFunc = [[
	local Players = game:GetService("Players")
	local TeleportService = game:GetService("TeleportService")
	
	TeleportService:Teleport%s
	local player = Players.LocalPlayer or Players.PlayerAdded:Wait()
	player:Kick()
]]
local forceTeleport = function(placeId, jobId) --bypasses third party teleport restrictions, which should be a built-in feature to synapse imo
	local s
	if jobId then
		s = string.format(tpFunc, string.format("ToPlaceInstance(%s, '%s')", placeId, jobId))
	else
		s = string.format(tpFunc, string.format("(%s)", placeId))
	end
	syn.queue_on_teleport(string.format(s, placeId, jobId))
	TeleportService:Teleport(game.PlaceId)
end

local boxLine = generalTab:SameLine()

local tpButton = boxLine:Button()
tpButton.Label = "Teleport"

local box = boxLine:TextBox()
generalTab:Label("Supports join strings, Place ID's, and Job ID's")
generalTab:Separator()

local clientTPCheck = generalTab:CheckBox()
local serverTPCheck = generalTab:CheckBox()

clientTPCheck.Label = "Allow Client-side Teleports"
serverTPCheck.Label = "Allow Server-side Teleports"
clientTPCheck.Value = true
serverTPCheck.Value = true

local serverTeleportConnection
task.spawn(function()
	local player = Players.LocalPlayer or Players.PlayerAdded:Wait()
	if not game:IsLoaded() then
		game.Loaded:Wait()
	end
	serverTeleportConnection = getconnections(player.OnTeleportInternal)[1]
end)
serverTPCheck.OnUpdated:Connect(function(activated)
	if serverTeleportConnection then
		if activated then
			serverTeleportConnection:Enable()
		else
			serverTeleportConnection:Disable()
		end
	else
		serverTPCheck.Value = true
	end
end)

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

local autoReconnectCheck = generalTab:CheckBox()
local showTimeoutCheck = generalTab:CheckBox()

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
		ConnectionError.DisconnectClientRequest,
		ConnectionError.DisconnectRaknetErrors,
		ConnectionError.DisconnectConnectionLost,
		TeleportResult.Failure,
		TeleportResult.Flooded
	},
	Cancel = {
		ConnectionError.DisconnectWrongVersion,
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
		TeleportResult.GameEnded,
		TeleportResult.GameFull
	}
}

local function rejoin(jobless)
	local thread = coroutine.running()
	local connection
	connection = TeleportService.TeleportInitFailed:Connect(function(player, result)
		TeleportService:TeleportCancel()
		for _, v in pairs(errorEnums.Retry) do
			if v == result then
				if jobless then
					TeleportService:Teleport(placeId)
				else
					TeleportService:TeleportToPlaceInstance(placeId, jobId)
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
				jobless = true
				TeleportService:Teleport(placeId)
			end
		end
	end)
	TeleportService:TeleportCancel()
	if jobless then
		TeleportService:Teleport(placeId)
	else
		TeleportService:TeleportToPlaceInstance(placeId, jobId)
	end
	return coroutine.yield()
end

tpButton.OnUpdated:Connect(function()
	local value = box.Value
	local jsPlaceId, jobId = parseJoinString(value)
	if jsPlaceId then
		forceTeleport(jsPlaceId, jobId)
	else
		local actualPlaceId = tonumber(value)
		if actualPlaceId then
			forceTeleport(actualPlaceId)
		elseif #value == 36 then
			TeleportService:TeleportToPlaceInstance(placeId, value)
		else
			rejoin(false)
		end
	end
end)

local save = function()
	writefile(fileName, HttpService:JSONEncode({
		autoreconnect = autoReconnectCheck.Value,
		timeout = showTimeoutCheck.Value
	}))
end
autoReconnectCheck.OnUpdated:Connect(save)
showTimeoutCheck.OnUpdated:Connect(save)

--autoreconnect

local function teleportCheck()
	if autoReconnectCheck.Value then
		local errorCode = GuiService:GetErrorCode()
		for _, v in pairs(errorEnums.Retry) do
			if v == errorCode then
				return rejoin(false)
			end
		end
		for _, v in pairs(errorEnums.Cancel) do
			if v == errorCode then
				game:Shutdown()
			end
		end
		for _, v in pairs(errorEnums.Jobless) do
			if v == errorCode then
				return rejoin(true)
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
	while task.wait() do --autoexecute shit
		if teleporting then
			teleportCheck()
			continue
		end
		local errorCode = GuiService:GetErrorCode()
		if (errorCode == Enum.ConnectionError.DisconnectConnectionLost or errorCode == Enum.ConnectionError.DisconnectDuplicatePlayer) and AutoReconnect and Stats.DataReceiveKbps == 0 and autoReconnectCheck.Value then
			TeleportService:TeleportToPlaceInstance(placeId, jobId)
			teleporting = true
		end
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
local addPlace = function(name, id)
	local selectable = uvTab:Selectable()
	local line = uvTab:SameLine()
	local separator = uvTab:Separator()
	local tpButton = line:Button()
	local copyButton = line:Button()
	
	selectable.Toggles = true
	line.Visible = false
	separator.Visible = false
	
	selectable.Label = name
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
		TeleportService:Teleport(id)
	end)
	copyButton.OnUpdated:Connect(function()
		setclipboard(tostring(id))
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
		copyButton.Label = "Copy Game Id"
		copyButton.OnUpdated:Connect(function()
			setclipboard(tostring(gameId))
		end)
		
		tpButton.Label = "Teleport to Start Place"
		tpButton.OnUpdated:Connect(function()
			TeleportService:Teleport(starterId)
		end)
		uvTab:Separator()
	end)
	if success then
		break
	end
end

local cursor
while true do
	while true do
		local success = pcall(function()
			local list = HttpService:JSONDecode(game:HttpGet(url .. "/places?sortOrder=Asc&limit=100&cursor=" .. (cursor or "")))
			local data = list.data
			for i = 1, #data do
				local placeData = data[i]
				local newId = placeData.id
				addPlace(placeData.name .. (placeId == newId and " - you are HERE" or ""), newId)
			end
			cursor = list.nextPageCursor
		end)
		if success then
			break
		end
	end
	if not cursor then
		break
	end
end

shared.TeleportUtilityRenderWindow = rw
