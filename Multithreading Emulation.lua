return {
	["Thread"] = function(f, ...)
		local e = Instance.new("BindableEvent")
		local fin
		e.Event:Connect(function(...)
			fin = true
		end)
		local thread = {
			["Finished"] = false,
			["Event"] = e,
			["join"] = function(self)
				local a = fin or {self.Event.Event:Wait()}
				if self.Event then
					self.Event:Destroy()
				end
				return {
					["Result"] = function()
						return unpack(self.Result)
					end,
					["Success"] = self.Success
					
				}
			end
		}
		local a = {...}
		spawn(function()
			local s, er = pcall(function()
				local r = {f(unpack(a))}
				thread.Result = r
				thread.Finished = true
				thread.Success = true
				thread.Event:Fire()
			end)
			if not s then
				thread.Result = {er}
				thread.Finished = true
				thread.Success = false
				thread.Event:Fire()
				error(er)
			end
		end)
		return thread
	end
}
