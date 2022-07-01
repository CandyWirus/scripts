--ATB User ID Scraper From File
--Written by Andy_Wirus#5999
--https://github.com/CandyWirus/scripts/blob/master/ATBUserIDScraper.lua
--Required functions: isfile, readfile, writefile, appendfile

local Path = "atb.txt" --There are no folder checks. If you would like this script to work with folders you will have to create them in advance.
local OnlyScrapePremium = true
local IgnoreLocalPlayer = true
local IgnoreFriends = false --A blocklist is a better option.


local Players = game:GetService("Players")
local LocalPlayer

local function PlayerAdded(player)
	if player == Players.LocalPlayer then
		LocalPlayer = player
		if IgnoreLocalPlayer then
			return
		end
	end
	if (player.MembershipType ~= Enum.MembershipType.None) or not OnlyScrapePremium then
		local uid = tostring(player.UserId)
		if isfile(Path) then
			if IgnoreFriends then
				if not LocalPlayer then
					while task.wait(.03) do
						if LocalPlayer then
							break
						end
					end
				end
				if (LocalPlayer ~= player) and player:IsFriendsWith(LocalPlayer.UserId) then
					return
				end
			end
			local ids = readfile(Path):split("\n")
			for i = 1, #ids do
				if ids[i] == uid then
					return
				end
			end
			appendfile(Path, "\n" .. uid)
		else
			writefile(Path, uid)
		end
	end
end

if game:IsLoaded() then --Assume not autoexecute
	for _, v in pairs(Players:GetPlayers()) do
		PlayerAdded(v)
	end
end

Players.PlayerAdded:Connect(PlayerAdded)
