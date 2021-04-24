repeat wait() until game:IsLoaded()

local player = game:GetService("Players").LocalPlayer

repeat wait() until game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("CanJoin"):InvokeServer(player) == "joinMatch"

for _,v in pairs(getconnections(player.PlayerGui:WaitForChild("UI"):WaitForChild("Intro"):WaitForChild("Play").MouseButton1Click)) do
	v.Function()
end

wait(1)

firetouchinterest(player.Character.PrimaryPart, workspace:WaitForChild("Map"):WaitForChild("Interactives"):WaitForChild("Exit"), 0)

wait(1)

game:GetService("ReplicatedStorage"):WaitForChild("ServerNetwork"):InvokeServer("EventCheck")