--Andy_Wirus#5999 for issues
--https://raw.githubusercontent.com/CandyWirus/scripts/master/TeleportUtility.lua

assert(RenderWindow, "no v3?? kys queuetard")

local module = {}
shared.TeleportUtility = module

--UI INITIALIZATION
local UI_NameLabel, UI_CustomTeleportButton, UI_ServerHopButton, UI_CustomTeleportTextBox, Function_AddUniverseViewerEntryUI, UI_ClientTeleportCheckMark, UI_ServerTeleportCheckMark, UI_ShowGameTeleportsCheckMark, UI_AutoReconnectCheckMark, UI_ShowTimeoutsCheckMark, UI_TeleportToStartPlaceButton, UI_CopyGameIdButton, UI_Tabs, UI_SortOrderCheckMark, UI_ExcludeFullGamesCheckMark, UI_SetServerPlaceButton, UI_ServerTextBox, UI_ServerListChildWindow
do
	local UI_RenderWindow = RenderWindow.new("Teleport Utility")

	UI_RenderWindow.DefaultSize = Vector2.new(550, 550)

	UI_Tabs = UI_RenderWindow:TabMenu()

	local generalTab = UI_Tabs:Add("General")

	local boxLine = generalTab:SameLine()

	UI_ServerHopButton = boxLine:Button()
	UI_CustomTeleportButton = boxLine:Button()
	UI_CustomTeleportTextBox = boxLine:TextBox()

	generalTab:Label("Supports join strings, Place ID's, and Job ID's")
	generalTab:Separator()
	UI_ClientTeleportCheckMark = generalTab:CheckBox()
	UI_ServerTeleportCheckMark = generalTab:CheckBox()
	UI_ShowGameTeleportsCheckMark = generalTab:CheckBox()
	generalTab:Separator()
	UI_SortOrderCheckMark = generalTab:CheckBox()
	UI_ExcludeFullGamesCheckMark = generalTab:CheckBox()
	generalTab:Separator()
	UI_AutoReconnectCheckMark = generalTab:CheckBox()
	UI_ShowTimeoutsCheckMark = generalTab:CheckBox()

	local uvTab = UI_Tabs:Add("Universe Viewer")

	local universeLine = uvTab:SameLine()

	UI_TeleportToStartPlaceButton = universeLine:Button()
	UI_CopyGameIdButton = universeLine:Button()
	
	uvTab:Separator()
	local universeChild = uvTab:Child()

	UI_NameLabel = universeLine:Label("Loading...")
	
	Function_AddUniverseViewerEntryUI = function(data)
		local selectable = universeChild:Selectable()
		local line = universeChild:SameLine()
		local separator = universeChild:Separator()
		local tpButton = line:Button()
		local copyButton = line:Button()
		local serverButton = line:Button()

		selectable.Toggles = true
		line.Visible = false
		separator.Visible = false

		tpButton.Label = "Teleport"
		copyButton.Label = "Copy ID"
		serverButton.Label = "View Servers"

		return selectable, line, separator, tpButton.OnUpdated, copyButton.OnUpdated, serverButton.OnUpdated
	end

	local serverTab = UI_Tabs:Add("Server List")

	local serverBoxLine = serverTab:SameLine()
	UI_SetServerPlaceButton = serverBoxLine:Button()
	UI_ServerTextBox = serverBoxLine:TextBox()

	serverTab:Separator()
	UI_ServerListChildWindow = serverTab:Child()

	Function_AddServerListEntryUI = function(data)
		local selectable = UI_ServerListChildWindow:Selectable()
		local line = UI_ServerListChildWindow:SameLine()
		local separator = UI_ServerListChildWindow:Separator()
		local tpButton = line:Button()
		local copyButton = line:Button()

		selectable.Toggles = true
		line.Visible = false
		separator.Visible = false

		tpButton.Label = "Teleport"
		copyButton.Label = "Copy ID"
		
		return selectable, line, separator, tpButton.OnUpdated, copyButton.OnUpdated
	end
	
	UI_ClientTeleportCheckMark.Label = "Allow Client-side Teleports"
	UI_ServerTeleportCheckMark.Label = "Allow Server-side Teleports"
	UI_ShowGameTeleportsCheckMark.Label = "Show Teleport Notifications"
	UI_AutoReconnectCheckMark.Label = "Auto Reconnect"
	UI_ShowTimeoutsCheckMark.Label = "Display connection time-outs"
	UI_SortOrderCheckMark.Label = "Sort servers by lowest player count"
	UI_ExcludeFullGamesCheckMark.Label = "Exclude full servers"
	UI_CustomTeleportButton.Label = "Teleport"
	UI_ServerHopButton.Label = "Server Hop"
	UI_TeleportToStartPlaceButton.Label = "Teleport to Start Place"
	UI_CopyGameIdButton.Label = "Copy Game ID"
	UI_SetServerPlaceButton.Label = "Refresh"

	module.RenderWindow = UI_RenderWindow
end

--VARIABLE DECLARATION
local TeleportService = cloneref(game:GetService("TeleportService"))
local HttpService = cloneref(game:GetService("HttpService")) --references to HttpService can be detected
local AssetService = cloneref(game:GetService("AssetService"))
local Players = cloneref(game:GetService("Players"))
local GuiService = cloneref(game:GetService("GuiService"))
local Stats = cloneref(game:GetService("Stats"))

local GetDebugId = game.GetDebugId

local queue_on_teleport = syn.queue_on_teleport
local get_thread_identity = syn.get_thread_identity
local set_thread_identity = syn.set_thread_identity


local ErrorEnumsString = [[
	local ConnectionError = Enum.ConnectionError
	local TeleportResult = Enum.TeleportResult

	return 
	{
		ConnectionError.TeleportErrors,
		ConnectionError.TeleportFailure,
		ConnectionError.TeleportFlooded,
		ConnectionError.DisconnectDuplicatePlayer,
		ConnectionError.DisconnectConnectionLost,
		ConnectionError.DisconnectReceivePacketError,
		ConnectionError.DisconnectReceivePacketStreamError,
		ConnectionError.DisconnectSendPacketError,
		TeleportResult.Failure,
		TeleportResult.Flooded
	},
	{
		ConnectionError.DisconnectWrongVersion,
		ConnectionError.DisconnectModeratedGame,
		ConnectionError.PlacelaunchHttpError,
		TeleportResult.GameNotFound
	},
	{
		ConnectionError.TeleportGameEnded,
		ConnectionError.TeleportUnauthorized,
		ConnectionError.TeleportGameFull,
		ConnectionError.DisconnectRobloxMaintenance,
		ConnectionError.PlacelaunchRestricted,
		ConnectionError.PlacelaunchGameEnded,
		ConnectionError.DisconnectDevMaintenance,
		ConnectionError.DisconnectClientRequest,
		ConnectionError.DisconnectRaknetErrors,
		TeleportResult.GameEnded,
		TeleportResult.GameFull,
		TeleportResult.Unauthorized
	}
]]
local RetryEnums, CancelEnums, JoblessEnums = loadstring(ErrorEnumsString)()

local SettingsFileName = "TeleportUtility.json"

--Declarations for Global_PlaceId, Global_GameId, Global_JobId
local Global_PlaceId = game.PlaceId
if Global_PlaceId == 0 then
	game:GetPropertyChangedSignal("PlaceId"):Wait()
	Global_PlaceId = game.PlaceId
end
local Global_GameId = game.GameId
if Global_GameId == 0 then
	game:GetPropertyChangedSignal("GameId"):Wait()
	Global_GameId = game.GameId
end
local Global_JobId = game.JobId
if Global_JobId == "" then
	game:GetPropertyChangedSignal("JobId"):Wait()
	Global_JobId = game.Jobid
end

UI_CustomTeleportTextBox.Value = `{Global_PlaceId}:{Global_JobId}`
UI_ServerTextBox.Value = tostring(Global_PlaceId)
local serverListPlaceId = Global_PlaceId

local url = syn.crypt.url
local encode = url.encode
local decode = url.decode

local sub = string.sub
local split = string.split
local find = string.find
local format = string.format

local serverUrl
do
	local indices = {}
	local ShittyUrl = {
		__index = function(t, k)
			return indices[t][k]
		end,
		__newindex = function(t, k, v)
			assert(typeof(k) == "string", `Invalid URL parameter: {k}`)
			indices[t][k] = tostring(v)
		end,
		__tostring = function(t)
			local data = ""
			for i, v in indices[t] do
				data ..= `&{encode(i)}={encode(v)}`
			end
			local final = t.BaseUrl .. "?" .. sub(data, 2, -1)
			if sub(final, -1, -1) == "?" then
				final = sub(final, 1, -2)
			end
			return final
		end
	}

	function ShittyUrl.new(baseUrl: string)
		local index = {}
		local argStart = find(baseUrl, "?")
		if argStart then
			local args = split(sub(baseUrl, argStart + 1, -1), "&")
			for i = 1, #args do
				local key, value = unpack(split(args[i], "="))
				if key and value then
					index[decode(key)] = decode(value)
				end
			end
		else
			argStart = 0 --bad code
		end
		local new = setmetatable({BaseUrl = sub(baseUrl, 1, argStart - 1)}, ShittyUrl)

		indices[new] = index
		return new
	end

	serverUrl = ShittyUrl.new("https://games.roblox.com/v1/games/%s/servers/Public?limit=100")
end

local Global_RootPlaceId

--SETTINGS INITIALIZATION
local SavedSettings, Function_SaveSettings
do
	local settingsIndex = {
		ClientTeleportsEnabled = true,
		ServerTeleportsEnabled = true,
		AutoReconnectEnabled = false,
		ShowConnectionTimeouts = false,
		ShowGameTeleports = false,
		SortOrder = false,
		ExcludeFullServers = false
	}

	assert(not isfolder(SettingsFileName), SettingsFileName .. " has been created as a folder. Teleport Utility cannot continue. Delete workspace\\" .. SettingsFileName .. " to use Teleport Utility.")

	if isfile(SettingsFileName) then
		local isJson, data = pcall(HttpService.JSONDecode, HttpService, readfile(SettingsFileName))
		if isJson then
			for i in settingsIndex do
				local savedValue = data[i]
				if savedValue ~= nil then
					settingsIndex[i] = savedValue
				end
			end
		end
	end

	do
		UI_ClientTeleportCheckMark.Value = settingsIndex.ClientTeleportsEnabled
		UI_ServerTeleportCheckMark.Value = settingsIndex.ServerTeleportsEnabled
		UI_ShowGameTeleportsCheckMark.Value = settingsIndex.ShowGameTeleports
		UI_AutoReconnectCheckMark.Value = settingsIndex.AutoReconnectEnabled
		UI_ShowTimeoutsCheckMark.Value = settingsIndex.ShowConnectionTimeouts

		local sortEnabled = settingsIndex.SortOrder
		local excludeEnabled = settingsIndex.ExcludeFullServers

		UI_SortOrderCheckMark.Value = sortEnabled
		UI_ExcludeFullGamesCheckMark.Value = excludeEnabled

		serverUrl.sortOrder = if sortEnabled then "1" else "2"
		serverUrl.excludeFullGames = excludeEnabled
	end

	SavedSettings = setmetatable({}, {
		__index = settingsIndex,
		__newindex = function(_, k, v)
			settingsIndex[k] = v
			writefile(SettingsFileName, HttpService:JSONEncode(settingsIndex))
		end
	})
end

UI_ClientTeleportCheckMark.OnUpdated:Connect(function()
	SavedSettings.ClientTeleportsEnabled = UI_ClientTeleportCheckMark.Value
end)

UI_ShowGameTeleportsCheckMark.OnUpdated:Connect(function()
	SavedSettings.ShowGameTeleports = UI_ShowGameTeleportsCheckMark.Value
end)

UI_AutoReconnectCheckMark.OnUpdated:Connect(function()
	SavedSettings.AutoReconnectEnabled = UI_AutoReconnectCheckMark.Value
end)

UI_ShowTimeoutsCheckMark.OnUpdated:Connect(function()
	SavedSettings.ShowConnectionTimeouts = UI_ShowTimeoutsCheckMark.Value
end)

UI_SortOrderCheckMark.OnUpdated:Connect(function()
	local enabled = UI_SortOrderCheckMark.Value
	serverUrl.sortOrder = if enabled then "1" else "2"
	SavedSettings.SortOrder = enabled
	if refreshServerList then
		refreshServerList()
	end
end)

UI_ExcludeFullGamesCheckMark.OnUpdated:Connect(function()
	local enabled = UI_ExcludeFullGamesCheckMark.Value
	serverUrl.excludeFullGames = enabled
	SavedSettings.ExcludeFullServers = enabled
	if refreshServerList then
		refreshServerList()
	end
end)

--TELEPORT FUNCTION SETUP

local PlacesInUniverseList = {Global_PlaceId}
local Teleport, CreateTeleportUtilityNotification 
do
	local CreateTeleportUtilityNotificationString = [[
		function(message, toastType)
			print(`[Teleport Utility] {message}`)
			syn.toast_notification({
				Type = toastType or 4,
				Title = "Teleport Utility",
				Content = message
			})
		end
	]]
	
	CreateTeleportUtilityNotification = loadstring("return " .. CreateTeleportUtilityNotificationString)()

	local forceBasicTeleportString = format([[
		local CreateTeleportUtilityNotification = %s

		local teleportBeganNotification = function(place, job)
			local str = "Teleporting to " .. tostring(place)
			if job then
				str ..= ":" .. job
			end
			str ..= "..."
			CreateTeleportUtilityNotification(str, 4)
		end

		local teleportFailedNotification = function(result)
			CreateTeleportUtilityNotification('Teleport failed with "' .. tostring(result) .. '"')
		end

		local RetryEnums, CancelEnums, JoblessEnums = loadstring([==[%s]==])()

		local TeleportService = game:GetService("TeleportService")

		return function(place, job)
			TeleportService:TeleportCancel()
			local thread = coroutine.running()
			local connection
			connection = TeleportService.TeleportInitFailed:Connect(function(player, result)
				teleportFailedNotification(result)
				TeleportService:TeleportCancel()
				for _, v in RetryEnums do
					if v == result then
						teleportBeganNotification(place, job)
						if job then
							return TeleportService:TeleportToPlaceInstance(place, job)
						else
							return TeleportService:Teleport(place)
						end
					end
				end
				for _, v in CancelEnums do
					if v == result then
						connection:Disconnect()
						return assert(coroutine.resume(thread, false))
					end
				end
				for _, v in JoblessEnums do
					if v == result then
						job = nil
						teleportBeganNotification(place)
						TeleportService:Teleport(place)
					end
				end
			end)
			teleportBeganNotification(place, job)
			if job then
				TeleportService:TeleportToPlaceInstance(place, job)
			else
				TeleportService:Teleport(place)
			end
			return coroutine.yield()
		end
	]], CreateTeleportUtilityNotificationString, ErrorEnumsString)
	local forceBasicTeleport = loadstring(forceBasicTeleportString)()

	local BaseQueuedString = format([[
		local TeleportService = game:GetService("TeleportService")

		local forceBasicTeleport = loadstring([=[%s]=])()

		if game.GameId == 0 then
			game:GetPropertyChangedSignal("GameId"):Wait() --Teleports will hang forever if initiated before game.GameId is loaded
		end
		syn.queue_on_teleport([=[
			settings():GetService("NetworkSettings").IncomingReplicationLag = 0 --IncomingReplicationLag persists across teleports, so reset it once you're in the game you wanted to join
		]=])
		forceBasicTeleport(%s, %s)
	]], forceBasicTeleportString, "%s", "%s")

	Teleport = function(place, job)
		task.spawn(function()
			local player = Players.LocalPlayer or Players.PlayerAdded:Wait()
			player:Kick("[Teleport Utility] You are being teleported.")
		end)
		local isSameUniverseTeleport = false
		for i = 1, #PlacesInUniverseList do
			if place == PlacesInUniverseList[i] then
				isSameUniverseTeleport = true
				break
			end
		end
		if isSameUniverseTeleport then
			if job then
				forceBasicTeleport(place, job)
			else
				forceBasicTeleport(place)
			end
		else
			local queuedString = format(BaseQueuedString, place, if job then '"' .. job .. '"' else "nil")
			queue_on_teleport(queuedString)
			settings():GetService("NetworkSettings").IncomingReplicationLag = math.huge
			forceBasicTeleport(Global_RootPlaceId or Global_PlaceId)
		end
	end
end

--BUTTONS THAT CAN BE SET UP IMMEDIATELY

do
	local parseJoinString = function(joinString)
		local index = find(joinString, ":")
		if index then
			return tonumber(sub(joinString, 1, index - 1)), sub(joinString, index + 1, -1)
		else
			return nil
		end
	end

	UI_CustomTeleportButton.OnUpdated:Connect(function()
		local input = UI_CustomTeleportTextBox.Value
		local parsedPlace, parsedJob = parseJoinString(input)
		if parsedPlace then
			Teleport(parsedPlace, parsedJob)
		else
			local place = tonumber(input)
			if place then
				Teleport(place)
			elseif #input == 36 then --length of a game.JobId GUID
				Teleport(Global_PlaceId, input)
			else
				if #Players:GetPlayers() > 1 then
					Teleport(Global_PlaceId, Global_JobId)
				else
					Teleport(Global_PlaceId)
				end
			end
		end
	end)
end

UI_ServerHopButton.OnUpdated:Connect(function()
	CreateTeleportUtilityNotification("Finding server to hop to...", 4)
	local success, servers = pcall(function()
		return HttpService:JSONDecode(game:HttpGet(`https://games.roblox.com/v1/games/{Global_PlaceId}/servers/Public?limit=100`)).data
	end)
	if success then
		local job
		while true do
			if #servers > 0 then
				local index = math.random(1, #servers)
				local server = servers[index]
				job = server.id
				if server.playing < server.maxPlayers and job ~= Global_JobId then
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
			Teleport(Global_PlaceId, job)
		else
			Teleport(Global_PlaceId)
		end
	else
		CreateTeleportUtilityNotification("Failed to fetch server list", 3)
	end
end)

--CLIENT TELEPORT HOOKS

do
	local othHook = syn.oth.hook

	local __namecall = getrawmetatable(game).__namecall
	restorefunction(__namecall)

	local NamecallFilter_Teleport = AllFilter.new({
		TypeFilter.new(2, "number"), --placeId
		AnyFilter.new({ --player
			TypeFilter.new(3, "userdata"),
			TypeFilter.new(3, "nil")
		}),
		AnyFilter.new({ --customLoadingScreen, needs additional filtering
			TypeFilter.new(5, "userdata"),
			TypeFilter.new(5, "nil")
		})
	})
	local NamecallFilter_TeleportToPlaceInstance = AllFilter.new({
		TypeFilter.new(2, "number"), --placeId
		TypeFilter.new(3, "string"), --instanceId
		AnyFilter.new({ --player
			TypeFilter.new(4, "userdata"),
			TypeFilter.new(4, "nil")
		}),
		AnyFilter.new({ --spawnName
			UserdataTypeFilter.new(5, game),
			NotFilter.new(TypeFilter.new(5, "userdata"))
		}),
		AnyFilter.new({ --customLoadingScreen, needs additional filtering
			TypeFilter.new(7, "userdata"),
			TypeFilter.new(7, "nil")
		})
	})
	local NamecallFilter_TeleportToSpawnByName = AllFilter.new({
		TypeFilter.new(2, "number"), --placeId
		AnyFilter.new({ --spawnName
			UserdataTypeFilter.new(3, game),
			NotFilter.new(TypeFilter.new(3, "userdata"))
		}),
		AnyFilter.new({ --player
			TypeFilter.new(4, "userdata"),
			TypeFilter.new(4, "nil")
		}),
		AnyFilter.new({ --customLoadingScreen, needs additional filtering
			TypeFilter.new(6, "userdata"),
			TypeFilter.new(6, "nil")
		})
	})

	do
		local originalNamecall
		originalNamecall = othHook(__namecall, function(...)
			local self = select(1, ...)
			
			local identity = get_thread_identity()
			set_thread_identity(7)
			local selfDebugId = typeof(self) == "Instance" and GetDebugId(self)
			local teleportServiceDebugId = GetDebugId(TeleportService) --this seems to change while the game is loading, so i decided not to cache it
			set_thread_identity(identity)
			
			if selfDebugId == teleportServiceDebugId and not checkcaller() then
				local method = getnamecallmethod()
				local customLoadingScreenIdx
				local hookFilter
				if method == "Teleport" then
					customLoadingScreenIdx = 5
					hookFilter = NamecallFilter_Teleport
				elseif method == "TeleportToPlaceInstance" then
					customLoadingScreenIdx = 7
					hookFilter = NamecallFilter_TeleportToPlaceInstance
				elseif method == "TeleportToSpawnByName" then
					customLoadingScreenIdx = 6
					hookFilter = NamecallFilter_TeleportToSpawnByName
				else
					return originalNamecall(...)
				end
				local placeId = select(2, ...)
				local jobId = select(3, ...) -- only for TeleportService:TeleportToPlaceInstance

				local baseNotifyString = ""
				if method == "TeleportToPlaceInstance" then
					baseNotifyString = " to " .. placeId .. ":" .. jobId .. "via TeleportService:TeleportToPlaceInstance."
				else
					baseNotifyString = " to " .. placeId .. " via call to TeleportService:" .. method .. "."
				end

				return getfilter(hookFilter, function(...)
					return originalNamecall(...)
				end, function(...)
					local customLoadingScreen = select(customLoadingScreenIdx, ...)
					if customLoadingScreen then
						local isCloneable = pcall(function()
							assert(customLoadingScreen:Clone()) --some protected objects error upon :Clone, while unprotected objects return nil if their Archivable is set to false
						end)
						if not isCloneable then
							return originalNamecall(...)
						end
					end
					if SavedSettings.ClientTeleportsEnabled then
						if UI_ShowGameTeleportsCheckMark.Value then
							CreateTeleportUtilityNotification("Teleporting" .. baseNotifyString, 4)
						end
						return originalNamecall(...)
					else
						if UI_ShowGameTeleportsCheckMark.Value then
							CreateTeleportUtilityNotification("Blocked teleport" .. baseNotifyString, 4)
						end
						return
					end
				end)(...)
			end
			
			return originalNamecall(...)
		end)
	end

	local IdxTeleport = TeleportService.Teleport
	local IdxTeleportToPlaceInstance = TeleportService.TeleportToPlaceInstance
	local IdxTeleportToSpawnByName = TeleportService.TeleportToSpawnByName

	local originalIdxTeleport, originalIdxTeleportToPlaceInstance, originalIdxTeleportToSpawnByName

	local IdxHook = function(self, customLoadingScreen)
		if typeof(self) == "Instance" then
			local identity = get_thread_identity()
			set_thread_identity(7)
			local selfDebugId = GetDebugId(self)
			local teleportServiceDebugId = GetDebugId(TeleportService)
			set_thread_identity(identity)
			
			if selfDebugId == teleportServiceDebugId and not SavedSettings.ClientTeleportsEnabled then
				if customLoadingScreen then
					local isCloneable = pcall(function()
						assert(customLoadingScreen:Clone()) --some protected objects error upon :Clone, while unprotected objects return nil if their Archivable is set to false
					end)
					if not isCloneable then
						return false
					end
				end
				return true
			end
		end
		return false
	end

	originalIdxTeleport = othHook(IdxTeleport, function(...)
		return getfilter(NamecallFilter_Teleport, originalIdxTeleport, function(...)
			local placeId = select(2, ...)
			if IdxHook(select(1, ...), select(5, ...)) then
				if UI_ShowGameTeleportsCheckMark.Value then
					CreateTeleportUtilityNotification("Blocked teleport to " .. placeId .. " via TeleportService.Teleport.", 4)
				end
				return
			else
				if UI_ShowGameTeleportsCheckMark.Value then
					CreateTeleportUtilityNotification("Teleporting to " .. placeId .. " via TeleportService.Teleport.", 4)
				end
				return originalIdxTeleport(...)
			end
		end)(...)
	end)

	originalIdxTeleportToPlaceInstance = othHook(IdxTeleportToPlaceInstance, function(...)
		return getfilter(NamecallFilter_TeleportToPlaceInstance, originalIdxTeleportToPlaceInstance, function(...)
			local placeId = select(2, ...)
			local jobId = select(3, ...)
			if IdxHook(select(1, ...), select(7, ...)) then
				if UI_ShowGameTeleportsCheckMark.Value then
					CreateTeleportUtilityNotification("Blocked teleport to " .. placeId .. ":" .. jobId .. " via TeleportService.TeleportToPlaceInstance.", 4)
				end
				return
			else
				if UI_ShowGameTeleportsCheckMark.Value then
					CreateTeleportUtilityNotification("Teleporting to " .. placeId .. ":" .. jobId .. " via TeleportService.TeleportToPlaceInstance.", 4)
				end
				return originalIdxTeleportToPlaceInstance(...)
			end
		end)(...)
	end)

	originalIdxTeleportToSpawnByName = othHook(IdxTeleportToSpawnByName, function(...)
		return getfilter(NamecallFilter_TeleportToSpawnByName, originalIdxTeleportToSpawnByName, function(...)
			local placeId = select(2, ...)
			if IdxHook(select(1, ...), select(6, ...)) then
				if UI_ShowGameTeleportsCheckMark.Value then
					CreateTeleportUtilityNotification("Blocked teleport to " .. placeId .. " via TeleportService.TeleportToSpawnByName.", 4)
				end
				return
			else
				if UI_ShowGameTeleportsCheckMark.Value then
					CreateTeleportUtilityNotification("Teleporting to " .. placeId .. " via TeleportService.TeleportToSpawnByName.", 4)
				end
				return originalIdxTeleportToSpawnByName(...)
			end
		end)(...)
	end)
end

--SERVER TELEPORT TOGGLE

do
	local ServerTeleportsConnection, ServerTeleportSignal

	local toggleServerTeleports = function(enabled)
		if ServerTeleportsConnection then
			if enabled then
				ServerTeleportsConnection:Enable()
			else
				ServerTeleportsConnection:Disable()
			end
		else
			UI_ServerTeleportCheckMark.Value = true
			SavedSettings.ServerTeleportsEnabled = true
		end
	end

	task.spawn(function()
		if not game:IsLoaded() then
			game.Loaded:Wait()
		end
		local player = Players.LocalPlayer or Players.PlayerAdded:Wait()
		ServerTeleportsConnection = getconnections(player.OnTeleportInternal)[1]
		ServerTeleportSignal = geteventmember(player, "OnTeleportInternal")
		local RequestedFromServer = Enum.TeleportState.RequestedFromServer
		ServerTeleportSignal:Connect(function(...)
			if UI_ShowGameTeleportsCheckMark.Value then
				if select(1, ...) == RequestedFromServer then
					local data = select(2, ...)
					local placeId = data.placeId
					local jobId = data.instanceId
					local strJobId = ":" .. jobId
					if strJobId == ":" then
						strJobId = ""
					end
					if UI_ServerTeleportCheckMark.Value then
						CreateTeleportUtilityNotification("Teleporting to " .. placeId .. strJobId .. " via server-sided request.", 4)
					else
						CreateTeleportUtilityNotification("Blocked teleport to " .. placeId .. strJobId .. " via server-sided request.", 4)
					end
				end
			end
		end)
		toggleServerTeleports(SavedSettings.ServerTeleportsEnabled)
	end)

	UI_ServerTeleportCheckMark.OnUpdated:Connect(function()
		local enabled = UI_ServerTeleportCheckMark.Value
		SavedSettings.ServerTeleportsEnabled = enabled
		toggleServerTeleports(enabled)
	end)
end

--AUTORECONNECT AND CONNECTION TIMEOUTS

do
	local NoErrorEnum = Enum.ConnectionError.OK

	local tryAutoReconnect = function()
		if Stats.DataReceiveKbps == 0 and SavedSettings.AutoReconnectEnabled then
			local errorCode = GuiService:GetErrorCode()
			if errorCode ~= NoErrorEnum then --prevents rejoin when game is loading
				for _, v in RetryEnums do
					if v == errorCode then
						return Teleport(Global_PlaceId, Global_JobId)
					end
				end
				for _, v in CancelEnums do
					if v == errorCode then
						return false
					end
				end
				for _, v in JoblessEnums do
					if v == errorCode then
						return Teleport(Global_PlaceId)
					end
				end
			end
		end
	end

	local lastTimestamp = tick()
	local lastKbps = 0
	local downTime = 0

	task.spawn(function()
		Drawing:WaitForRenderer()
		local UI_TimeoutBanner = PolyLineDynamic.new({
			Point2D.new(0, 0, .3, 0),
			Point2D.new(1, 0, .3, 0),
			Point2D.new(1, 0, .35, 0),
			Point2D.new(0, 0, .35, 0)
		})
		UI_TimeoutBanner.Color = Color3.fromRGB(51, 51, 51)
		UI_TimeoutBanner.Opacity = .8
		UI_TimeoutBanner.FillType = 2
		
		local UI_TimeoutText = TextDynamic.new(Point2D.new(.5, 0, .325, 0))
		UI_TimeoutText.Size = 80
		UI_TimeoutText.Color = Color3.fromRGB(241, 241, 241)
		UI_TimeoutText.Font = DrawFont.RegisterDefault("Inconsolata_Regular", {
			PixelSize = 120,
			UseStb = false,
			Scale = true,
			Bold = false
		})
		
		UI_TimeoutBanner.Visible = false
		UI_TimeoutText.Visible = false
		while task.wait(.03) do
			local timestamp = tick()
			local currentKbps = Stats.DataReceiveKbps
			if currentKbps == lastKbps then
				if GuiService:GetErrorCode() == NoErrorEnum then
					downTime += (timestamp - lastTimestamp)
					local shouldBannerDisplay = SavedSettings.ShowConnectionTimeouts and downTime > 1 and game:IsLoaded()
					UI_TimeoutText.Visible = shouldBannerDisplay
					UI_TimeoutBanner.Visible = shouldBannerDisplay
					UI_TimeoutText.Text = format("Server not responding... %0.2f", downTime)
				else
					local shouldBannerDisplay = SavedSettings.ShowConnectionTimeouts and game:IsLoaded() and SavedSettings.AutoReconnectEnabled
					UI_TimeoutText.Text = "Reconnecting..."
					UI_TimeoutText.Visible = shouldBannerDisplay
					UI_TimeoutBanner.Visible = shouldBannerDisplay
					tryAutoReconnect()
				end
			else
				downTime = 0
			end
			lastTimestamp = timestamp
			lastKbps = currentKbps
		end
	end)
end

--UNIVERSE VIEWER

do
	local displayedUniverseViewerElements = {}

	local setupUniverseViewerEntry = function(data)
		local selectable, sameLine, separator, teleportButtonEvent, copyButtonEvent, viewServersEvent = Function_AddUniverseViewerEntryUI()
		local entryPlaceId = data.PlaceId
		local gameName = data.Name
		if Global_PlaceId == entryPlaceId then
			selectable.Label = gameName .. " - you are HERE"
		else
			selectable.Label = gameName
			table.insert(PlacesInUniverseList, entryPlaceId)
		end

		teleportButtonEvent:Connect(function()
			Teleport(entryPlaceId)
		end)

		do
			local placeText = tostring(entryPlaceId)
			copyButtonEvent:Connect(function()
				CreateTeleportUtilityNotification(format("Copied %s (%s) to clipboard", placeText, gameName), 1)
				setclipboard(placeText)
			end)
		end

		viewServersEvent:Connect(function()
			serverListPlaceId = entryPlaceId
			UI_Tabs.SelectedItem = 3 --hardcoded because not readable
			if refreshServerList then
				--refreshServerList()
			end
		end)

		local toggle = false
		selectable.OnUpdated:Connect(function()
			if displayedUniverseViewerElements[1] == selectable or displayedUniverseViewerElements[1] == nil then
				toggle = not toggle
				selectable.Value = toggle
				sameLine.Visible = toggle
				separator.Visible = toggle
			elseif displayedUniverseViewerElements[1] then
				toggle = true
				displayedUniverseViewerElements[1].Value = false
				displayedUniverseViewerElements[2].Visible = false
				displayedUniverseViewerElements[3].Visible = false
				selectable.Value = true
				sameLine.Visible = true
				separator.Visible = true
			end
			displayedUniverseViewerElements[1] = selectable
			displayedUniverseViewerElements[2] = sameLine
			displayedUniverseViewerElements[3] = separator
		end)
		
	end

	task.spawn(function()
		local pages = AssetService:GetGamePlacesAsync()

		while true do
			for _, v in pages:GetCurrentPage() do
				setupUniverseViewerEntry(v)
			end
			if pages.IsFinished then
				break
			end
			pages:AdvanceToNextPageAsync()
		end
	end)
end

--UNIVERSE DETAILS

task.spawn(function()
	local url = "https://develop.roblox.com/v1/universes/" .. Global_GameId

	while true do
		local success = pcall(function()
			local data = HttpService:JSONDecode(game:HttpGet(url))
			
			local gameName = data.name
			UI_NameLabel.Label = gameName
			Global_RootPlaceId = data.rootPlaceId
			
			local placeText = tostring(Global_GameId)
			UI_CopyGameIdButton.OnUpdated:Connect(function()
				CreateTeleportUtilityNotification(format("Copied %s (%s) to clipboard", placeText, gameName), 1)
				setclipboard(placeText)
			end)
			
			UI_TeleportToStartPlaceButton.OnUpdated:Connect(function()
				Teleport(Global_RootPlaceId)
			end)
		end)
		if success then
			break
		else
			task.wait(5)
		end
	end
end)

--SERVERLIST
local getServerList = function(placeId)
	local url = format(tostring(serverUrl), placeId)
	local body = game:HttpGet(url)
	local success, data = pcall(HttpService.JSONDecode, HttpService, body)
	if success then
		local errors = data.errors
		if errors then
			local str = "Roblox API Error:"
			for i = 1, #errors do
				local err = errors[i]
				local code = err.code
				local message = err.message
				str ..= `\n\tCode {code}: {message}`
			end
			CreateTeleportUtilityNotification(str, 2)
			return false
		end
		return data.data, data.nextPageCursor
	end
	return false
end

local selectedJobId = nil

refreshServerList = function()
	local currentPlaceId = serverListPlaceId
	local serverList, cursor = getServerList(currentPlaceId)
	if serverList then
		UI_ServerListChildWindow:Clear()
		local displayedServerListElements = {}
		for i = 1, #serverList do
			local server = serverList[i]
			local selectable, sameLine, separator, tpEvent, copyEvent = Function_AddServerListEntryUI()
			local label = `{server.playing or 0}/{server.maxPlayers or 0} players @ {math.round(server.fps or 0)} FPS & {server.ping or 0} ms ping`

			local serverJobId = server.id

			if server.id == Global_JobId then
				label ..= " - you are HERE"
			end
			selectable.Label = label

			tpEvent:Connect(function()
				Teleport(currentPlaceId, serverJobId)
			end)

			copyEvent:Connect(function()
				CreateTeleportUtilityNotification(format("Copied %s to clipboard", serverJobId), 1)
				setclipboard(serverJobId)
			end)

			local toggle = false
			local onUpdated = function()
				if displayedServerListElements[1] == selectable or displayedServerListElements[1] == nil then
					toggle = not toggle
					selectable.Value = toggle
					sameLine.Visible = toggle
					separator.Visible = toggle
				elseif displayedServerListElements[1] then
					toggle = true
					displayedServerListElements[1].Value = false
					displayedServerListElements[2].Visible = false
					displayedServerListElements[3].Visible = false
					selectable.Value = true
					sameLine.Visible = true
					separator.Visible = true
				end
				if toggle then
					selectedJobId = serverJobId
				else
					selectedJobId = nil
				end
				displayedServerListElements[1] = selectable
				displayedServerListElements[2] = sameLine
				displayedServerListElements[3] = separator
			end
			if selectedJobId == serverJobId then
				onUpdated()
			end
			selectable.OnUpdated:Connect(onUpdated)
		end
	else
		return false
	end
end

UI_SetServerPlaceButton.OnUpdated:Connect(function()
	local value = tonumber(UI_ServerTextBox.Value)
	if value then
		serverListPlaceId = value
		refreshServerList()
	end
end)

UI_Tabs.OnUpdated:Connect(function(idx)
	if idx == 3 then --hardcoded because idx isn't readable
		refreshServerList()
	end
end)

task.spawn(refreshServerList)
