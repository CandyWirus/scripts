local HTTPService = game:GetService("HttpService")

local yes, servers = pcall(function()
	return HTTPService:JSONDecode(syn.request({
		Url = "https://games.roblox.com/v1/games/" .. tostring(game.PlaceId) .. "/servers/Public?limit=100",
		Method = "GET"
	}).Body).data
end)

if not yes then return end

local server, pos

repeat
	if pos then
		table.remove(servers, pos)
	end
	pos = math.random(1, #servers)
	server = servers[pos]
until ((server.playing < server.maxPlayers) and server.id ~= game.JobId) or #servers == 0

if #servers > 0 then
	game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId, server.id)
	return true
end
return false
