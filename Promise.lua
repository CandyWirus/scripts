return {
	["new"] = function(f, ...)
		local e = Instance.new("BindableEvent")
		local fin, result
		e.Event:Connect(function()
			fin = true
			e:Destroy()
		end)
		local promise = {
			["Finished"] = false,
			["Event"] = e,
			["join"] = function(self)
				local a = fin or {self.Event.Event:Wait()}
				if self.Event then
					self.Event:Destroy()
				end
				return self
			end,
			["Result"] = function()
				if result then
					return unpack(result)
				else
					error("Cannot get result of Promise: Computation Incomplete (use Promise:join())")
				end
			end
		}
		local a = {...}
		spawn(function()
			local s, er = pcall(function()
				local r = {f(unpack(a))}
				result = r
				promise.Finished = true
				promise.Success = true
				promise.Event:Fire()
			end)
			if not s then
				result = {er}
				promise.Finished = true
				promise.Success = false
				promise.Event:Fire()
				error(er)
			end
		end)
		return promise
	end
}
