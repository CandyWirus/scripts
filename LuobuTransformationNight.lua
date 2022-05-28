--Andy_Wirus#5999
--https://github.com/CandyWirus/scripts/blob/master/LuobuTransformationNight.lua
--https://v3rmillion.net/showthread.php?tid=1171439
--https://www.roblox.com/games/7733392089
--If you want to get every item, you will need to run this script in game every day
--If you do it with a friended alt, it will take 23 + 1/3 days. If you do it alone, it will take you 70 days.
--Weekly rewards give an extra 300 candies a week. You can complete them by making your friendly alt rejoin 10 times, you don't actually need 10 friends.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer or Players.PlayerAdded:Wait()

local PlayerData = ReplicatedStorage:WaitForChild("PlayerData"):WaitForChild(player.Name)
local danceFlag = PlayerData:WaitForChild("DailyRemainDanceCount")
local touchPart = workspace:WaitForChild("StageTouch"):WaitForChild("StageTouch")
workspace.StageTouch:PivotTo(workspace.StageTouch:GetPivot() + Vector3.new(0, -100000, 0)) --because you autists can't sit still

if not game:IsLoaded() then
	game.Loaded:Wait()
end

--START SETTINGS

local Autobuy = false --barely tested so default value is false
local StopIfNoFriends = true --having 1 friend in the game dancing gives a 3x bonus, which is valuable when you can only claim candies 20 times a day. this bonus does not stack with more friends

--END SETTINGS

local function getFriendInGame()
	for _, v in pairs(Players:GetPlayers()) do
		if v ~= player and v.Character and v.Character:FindFirstChild("IsDancing") --[[you could name a hat IsDancing and break this game by wearing it]] and v.Character.IsDancing.Value and player:IsFriendsWith(v.UserId) then
			return true
		end
	end
	return not StopIfNoFriends
end

local function getCharacter()
	return player.Character or player.CharacterAdded:Wait()
end

local function getRoot()
	while true do
		if getCharacter().PrimaryPart then
			return getCharacter().PrimaryPart
		end
		task.wait(1)
	end
end

while true do
	if danceFlag.Value <= 0 then
		break
	elseif getFriendInGame() then
		if getCharacter():WaitForChild("IsInStage_Client").Value then
			getsenv(player.PlayerGui.MainUI.DanceFrame.DanceFrame).Dance()
			danceFlag.Changed:Wait()
		else
			local root = getRoot()
			firetouchinterest(touchPart, root, 0)
			firetouchinterest(touchPart, root, 1)
			task.wait(1)
		end
	else
		print("You ain't got no friends 🤣! Or they're not on stage dancing, which is required for the bonus. Move your alt!")
		task.wait(3)
	end
end

if Autobuy then
	for i = 1, 10 do
		ReplicatedStorage.RemoteEvents.CandyExchangeEvent:FireServer(i)
	end
end

print("Script has run to completion. Have fun running it again tomorrow.")
