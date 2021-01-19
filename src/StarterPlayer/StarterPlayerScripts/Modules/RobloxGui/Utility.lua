local Util = {}
do
	function Util:Create(instanceType)
		return function(data)
			local obj = Instance.new(instanceType)
			local parent = nil
			for k, v in pairs(data) do
				if type(k) == 'number' then
					v.Parent = obj
				elseif k == 'Parent' then
					parent = v
				else
					obj[k] = v
				end
			end
			if parent then
				obj.Parent = parent
			end
			return obj
		end
	end
end
return Util;