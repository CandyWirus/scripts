--Andy_Wirus#5999 for issues
--https://raw.githubusercontent.com/CandyWirus/scripts/master/UniverseViewerV3.lua

local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")

local rw = RenderWindow.new("Universe Viewer")

local placeId = game.PlaceId
local gameId = game.GameId

if gameId == 0 then --autoexecute compatibility
	game:GetPropertyChangedSignal("GameId"):Wait()
	gameId = game.GameId
end

local function addPlace(name, id)
	local line = rw:SameLine()
	local tpButton = line:Button()
	local copyButton = line:Button()
	tpButton.Label = "Teleport"
	copyButton.Label = "Copy ID"
	tpButton.OnUpdated:Connect(function()
		TeleportService:Teleport(id)
	end)
	copyButton.OnUpdated:Connect(function()
		setclipboard(tostring(id))
	end)
	line:Label(name)
end

local cursor
while true do
	while true do
		local success = pcall(function()
			local list = HttpService:JSONDecode(game:HttpGet("https://develop.roblox.com/v1/universes/" .. gameId .. "/places?sortOrder=Asc&limit=100&cursor=" .. (cursor or "")))
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

shared.UniverseViewerRenderWindow = rw
