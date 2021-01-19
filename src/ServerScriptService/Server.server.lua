-- Main
-- Tom Mackintosh
-- 11th January 2021
-- modifed by neztore 17th Jan

local ServerStorage = game:GetService("ServerStorage")

function checkFolder(folder)
	for _, item in pairs (folder:GetChildren()) do
		if item:IsA("ModuleScript") then
			local s,e = pcall(function ()
				require(item):Run()
			end)
			if e then
				warn(e)
			end
		elseif item:IsA("Folder") then
			checkFolder(item)
		end
	end
end


if ServerStorage.Modules then
	checkFolder(ServerStorage.Modules)
	print("Server initialised.")
else
	warn("Server Scripts not configured. Please create folder called \"Modules\" in ServerStorage.")
end

