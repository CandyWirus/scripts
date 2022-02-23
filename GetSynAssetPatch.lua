if not islclosure(getsynasset) then
	local folderName = "SynAssetStorage"

	if isfolder(folderName) then
		delfolder(folderName)
	end

	makefolder(folderName)

	local function randomChar()
		return math.random(0, 1) == 0 and string.char(math.random(65, 90)) or string.char(math.random(97, 122))
	end

	local function randomString(length)
		local s = ""
		for i = 1, length do
			s = s .. randomChar()
		end
		return s
	end

	local oldGetAsset = getsynasset

	getgenv().getsynasset = function(url)
		if isfile(url) then
			return oldGetAsset(url)
		end
		local extension = string.split(url, ".")[#string.split(url, ".")]
		local file = syn.request({
			Url = url,
			Method = "GET"
		}).Body
		local name
		repeat
			name = randomString(20) .. "." .. extension
		until not isfile(folderName .. "/" .. name)
		writefile(folderName .. "/" .. name, file)
		local assetId = oldGetAsset(folderName .. "/" .. name)
		return assetId, folderName .. "/" .. name
	end

	game.Close:Connect(function()
		if isfolder(folderName) then
			delfolder(folderName)
		end
	end)
end
