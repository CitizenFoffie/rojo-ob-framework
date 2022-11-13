--[[
	// Name: OBFramework
	// By: pos0
	// GitHub: https://github.com/p0s0/ob-framework
	// Created: 9/7/21
	// Updated: 12/30/21
	// Version: 1.6
	//
	// To load this module, you can call require(script.Parent:WaitForChild("MainModule")):Load("PeriodName") from a Script in 
	// ServerScriptService.
	//
	// Time period dates (CS + PS):
	// 2014E: 4/22/14
	// 2014M: 6/24/14
	// 2014L: 11/3/14
	// 2015E: 2/25/15
	// 2015M: 6/24/15
	// 2015L: 11/3/15
	// 2016E: 2/26/16
	// 2016M: 6/24/16
	// 2016L: 11/3/16
	//
	// TODOs:
	// Move CoreScripts to ServerStorage.
	// Do we actually need to destroy OB_Extra? Review.
	// Remove all Script Analysis warnings / Clean up Script Analysis.
	// Finish PersonalServerService.
	// Add all of the LoadingScripts. (DONE!)
	// Fix all of the "Flag does not exist" warnings
--]]
--
local framework = {}
local loaded = false
--
local timePeriods = script:WaitForChild("Periods")
local rs = game.ReplicatedStorage
local servs = game.ServerStorage
local debugPrints = false
local scriptVersion = 1.6
--
local sp = game.StarterPlayer.StarterPlayerScripts
--
local pm = game.StarterPlayer.StarterPlayerScripts:WaitForChild("PlayerModule")
local psl = game.StarterPlayer.StarterPlayerScripts:WaitForChild("PlayerScriptsLoader")
--
pm:Destroy()
psl:Destroy()
--
local gameObjects = { -- will be updated as time goes on
	game.Workspace,
	game.Players,
	game.Lighting,
	game.ReplicatedFirst,
	game.ReplicatedStorage,
	game.ServerScriptService,
	game.ServerStorage,
	game.StarterGui,
	game.StarterPack,
	game.StarterPlayer,
	game.StarterPlayer.StarterPlayerScripts,
	game.StarterPlayer.StarterCharacterScripts,
	game.SoundService,
	game.Chat,
	game.LocalizationService,
	game.TestService
}
--
function getGameChildren() -- thanks for the security check roblox
	return gameObjects
end
--
function unpackFolder(folder, newParent)
	for v,i in pairs(folder:GetChildren()) do
		i.Parent = newParent
		
		if i:IsA("Script") or i:IsA("LocalScript") then
			if i.Disabled and not i:FindFirstChild("OBDoNotEnable") then
				i.Disabled = false
			end
		end
	end
	--
	folder:Destroy()
	--
	return newParent
end
--
function packFolder(objects, parent, name)
	local folder = Instance.new("Folder")
	for v,i in pairs(objects) do
		i.Parent = folder
	end
	folder.Name = tostring(name) -- just-in-case
	folder.Parent = parent
	--
	return folder
end
--
function disableDisplayHud()
	for v,i in pairs(game:GetDescendants()) do
		pcall(function()
			if i:IsA("VehicleSeat") then
				local val = Instance.new("BoolValue")
				val.Name = "OB_HeadsUpDisplay"
				val.Value = i.HeadsUpDisplay
				val.Parent = i
				--
				i.HeadsUpDisplay = false
				--
				i.Changed:Connect(function(prop)
					if prop == "HeadsUpDisplay" then
						val.Value = i.HeadsUpDisplay
						i.HeadsUpDisplay = false
					end
				end)
			end
		end)
	end
end
--
function destroyDefaultPlayerScripts()
	if sp:FindFirstChild("BubbleChat") then
		sp.BubbleChat:Destroy()
	end
	if sp:FindFirstChild("ChatScript") then
		sp.ChatScript:Destroy()
	end
	if sp:FindFirstChild("RbxCharacterSounds") then
		sp.RbxCharacterSounds:Destroy()
	end
end
--
function framework:Configure(settingTable)
	if loaded ~= true then warn("The Framework must be loaded to configure options!") return end
	if settingTable == nil then warn("SettingTable for Configure is nil. It cannot be nil!") return end
	if typeof(settingTable) ~= "table" then warn("SettingTable for Configure is not a Table. It must be a table!") return end
	--
	local gs = require(game.ReplicatedStorage:WaitForChild("OB_Services"):WaitForChild("GlobalSettings"))
	--
	for v,i in pairs(settingTable) do
		gs:ConfigureSetting(v, i)
	end
	--
	return true
end
--
function framework:GetSettingVal(setting)
	if setting == nil then warn("Setting can not be nil for GetSettingVal!") return end
	if loaded ~= true then warn("The Framework must be loaded to get setting values!") return end
	--
	local gs = require(game.ReplicatedStorage:WaitForChild("OB_Services"):WaitForChild("GlobalSettings"))
	--
	if gs[setting] ~= nil then
		return gs[setting]
	end
	--
	return nil
end
--
function framework:SetSettingVal(setting, value)
	if setting == nil then warn("Setting can not be nil for SetSettingVal!") return end
	if loaded ~= true then warn("The Framework must be loaded to set values for GlobalSettings!") return end
	--
	local gs = require(game.ReplicatedStorage:WaitForChild("OB_Services"):WaitForChild("GlobalSettings"))
	--
	if gs[setting] ~= nil then
		gs:ConfigureSetting(setting, value)
		return true
	end
	--
	return nil
end
--
function _G:GetService(serviceName, isRaw)
	if isRaw == nil then isRaw = false end
	local returnVal = game:GetService("ReplicatedStorage"):WaitForChild("OB_Services"):FindFirstChild(tostring(serviceName))
	if not returnVal then
		warn("'" .. tostring(serviceName) .. "' is not a valid Service name")
	else
		return isRaw and returnVal or require(returnVal)
	end
end
--
function _G:GetTrueName(plr)
	if _G:GetService("GlobalSettings"):GetFFlag("UseDisplayNames") then
		return plr.DisplayName
	else
		return plr.Name
	end
end
--
function framework:IsLoaded()
	return loaded
end
--
function framework:Load(period) -- period String
	if not period then warn("OBFramework: framework::Load(period) called, but period is nil. Defaulting to 2015E") period = "2015E" end -- come on roblox, if i could bump this i would https://devforum.roblox.com/t/function-default-argument-declaration/531450
	--
	loaded = true
	local realPeriod = string.sub(tostring(period), 1, 4)
	local realEml = string.sub(tostring(period), 5, 5)
	-- not my code
	game.Players.PlayerAdded:Connect(function(player)
		local idled = false
		--
		local function onPlayerIdled(timeIdled)
			if timeIdled >= 15*60 then
				player:Kick(string.format("You were disconnected for being idle %d minutes", timeIdled/60), "Idle", "Idle")
				if not idled then
					idled = true
				end
			end
		end
		--
		player.Idled:Connect(onPlayerIdled)
	end)
	-- my code
	period = realPeriod .. realEml
	if debugPrints then print(tostring(period)) end
	--
	local obExtra = script:WaitForChild("Global"):WaitForChild("StarterPlayerScripts"):WaitForChild("OB_Extra"):Clone()
	obExtra.Parent = sp
	script.Global.StarterPlayerScripts.OB_Extra:Destroy() -- do we actually need to destroy this?
	--
	local periodVal = Instance.new("StringValue")
	periodVal.Name = "OB_Period"
	periodVal.Value = period
	periodVal.Parent = rs
	--
	local versionVal = Instance.new("NumberValue")
	versionVal.Name = "OB_Version"
	versionVal.Value = scriptVersion
	versionVal.Parent = rs
	--
	local rrr = Instance.new("Folder")
	rrr.Name = "RobloxReplicatedStorage"
	rrr.Parent = game:GetService("ReplicatedStorage")
	-- this code is taken from the CoreScripts
	coroutine.wrap(function()
		--[[
			// Filename: ServerStarterScript.lua
			// Version: 1.0
			// Description: Server core script that handles core script server side logic.
		]]--
		--
		-- Prevent server script from running in Studio when not in run mode
		local runService = nil
		while runService == nil or not runService:IsRunning() do
			wait(0.1)
			runService = game:GetService('RunService')
		end
		--
		--[[ Services ]]--
		local RobloxReplicatedStorage = rrr
		--
		--[[ Remote Events ]]--
		local RemoteEvent_OnNewFollower = Instance.new('RemoteEvent')
		RemoteEvent_OnNewFollower.Name = "OnNewFollower"
		RemoteEvent_OnNewFollower.Parent = RobloxReplicatedStorage
		--
		local RemoteEvent_SetDialogInUse = Instance.new("RemoteEvent")
		RemoteEvent_SetDialogInUse.Name = "SetDialogInUse"
		RemoteEvent_SetDialogInUse.Parent = RobloxReplicatedStorage
		--
		local RemoteFunc_GetFollowRelationships = Instance.new("RemoteFunction")
		RemoteFunc_GetFollowRelationships.Name = "GetFollowRelationships"
		RemoteFunc_GetFollowRelationships.Parent = RobloxReplicatedStorage
		--
		local RemoteEvent_FollowRelationshipChanged = Instance.new("RemoteEvent")
		RemoteEvent_FollowRelationshipChanged.Name = "FollowRelationshipChanged"
		RemoteEvent_FollowRelationshipChanged.Parent = RobloxReplicatedStorage
		--
		--[[ Event Connections ]]--
		-- Params:
			-- followerRbxPlayer: player object of the new follower, this is the client who wants to follow another
			-- followedRbxPlayer: player object of the person being followed
		local function onNewFollower(followerRbxPlayer, followedRbxPlayer)
			RemoteEvent_OnNewFollower:FireClient(followedRbxPlayer, followerRbxPlayer)
		end
		RemoteEvent_OnNewFollower.OnServerEvent:Connect(onNewFollower)
		--
		local function setDialogInUse(player, dialog, value)
			if dialog ~= nil then
				dialog.InUse = value
			end
		end
		RemoteEvent_SetDialogInUse.OnServerEvent:Connect(setDialogInUse)
	end)()
	--
	for v,i in pairs(script:WaitForChild("Global"):GetChildren()) do
		if game:FindFirstChild(i.Name) then
			unpackFolder(i, game[i.Name])
		else
			for b,o in pairs(getGameChildren()) do
				if o.Name == i.Name then
					unpackFolder(i, o)
				end
			end
		end
	end
	--
	if tonumber(realPeriod) == 2016 and realEml == "L" then
		local chatServiceFolder = game:GetService("ReplicatedStorage"):WaitForChild("OB_ChatService")
		unpackFolder(chatServiceFolder, game:GetService("ReplicatedStorage"))
	end
	--
	if tonumber(realPeriod) == 2015 and realEml == "E" or tonumber(realPeriod) <= 2014 then
		local function addHealthBarGui(model)
			if model.Parent:FindFirstChildOfClass("Humanoid") and model.Parent:FindFirstChild("Head") and not model.Parent.Head:FindFirstChild("HealthBarGui") then
				local hbg = game.ServerStorage:WaitForChild("HealthBarGui"):Clone()
				local hum = model.Parent:FindFirstChildOfClass("Humanoid")
				hbg.NameLabel.Text = model.Parent.Name
				hbg.Parent = model.Parent.Head
				hbg.MaxDistance = model.Parent:FindFirstChildOfClass("Humanoid").NameDisplayDistance
				hbg.HealthBar.Visible = hum.HealthDisplayType ~= Enum.HumanoidHealthDisplayType.AlwaysOff and true or false
				hbg.Enabled = hum.DisplayDistanceType ~= Enum.HumanoidDisplayDistanceType.None and true or false

				hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
				hum.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff

				model.Parent.Changed:Connect(function()
					if game.Players:GetPlayerFromCharacter(model.Parent) == nil and model ~= nil and model.Parent ~= nil then
						hbg.NameLabel.Text = model.Parent.Name
					end
				end)
				
				hum.Changed:Connect(function()
					local uwidth = (hum.Health / hum.MaxHealth)
					local width = uwidth * 0.96

					hbg.HealthBar.Bar.Size = UDim2.new(uwidth, 0, 1, 0)
				end)
			end
		end
	
		for v,i in pairs(workspace:GetDescendants()) do
			addHealthBarGui(i)
		end

		workspace.DescendantAdded:Connect(function(model)
			addHealthBarGui(model)
		end)
	else
		local function changeHumanoidProps(model)
			if model.Parent:FindFirstChildOfClass("Humanoid") then
				local hum = model.Parent:FindFirstChildOfClass("Humanoid")
				hum.DisplayName = model.Parent.Name
				hum.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOn
			end
		end
		
		for v,i in pairs(workspace:GetDescendants()) do
			changeHumanoidProps(i)
		end

		workspace.DescendantAdded:Connect(function(model)
			changeHumanoidProps(model)
		end)
	end
	--
	rs:WaitForChild("OB_Functions"):WaitForChild("GetPeriod").OnServerInvoke = function(plr)
		return period--tostring(realPeriod .. realEml)
	end
	--
	rs:WaitForChild("OB_Functions"):WaitForChild("GetVersion").OnServerInvoke = function(plr)
		return scriptVersion
	end
	--
	if timePeriods:FindFirstChild(period) then
		for v,i in pairs(timePeriods[period]:GetChildren()) do
			if game:FindFirstChild(i.Name) then
				unpackFolder(i, game[i.Name])
			else
				for b,o in pairs(getGameChildren()) do
					if o.Name == i.Name then
						unpackFolder(i, o)
					end
				end
			end
		end
		destroyDefaultPlayerScripts()
	else
		warn("OBFramework: framework::Load(period) called, but period is not found. Make sure the time period is inside of OBFramework.Periods. The naming format is '(year)(EML)'. For example: 2014L")
		return false
	end
	--
	disableDisplayHud()
	--
	for v,i in pairs(workspace:GetDescendants()) do
		if i:IsA("Hat") or i:IsA("Accessory") then
			if i:FindFirstChild("Handle") then
				i.Handle.Material = Enum.Material.SmoothPlastic
			end
		end
	end
	--
	workspace.DescendantAdded:Connect(function(i)
		if i:IsA("Hat") or i:IsA("Accessory") then
			if i:FindFirstChild("Handle") then
				i.Handle.Material = Enum.Material.SmoothPlastic
			end
		end
	end)
	--
	local OBSoundGroup = Instance.new("SoundGroup")
	OBSoundGroup.Name = "OBSoundGroup"
	OBSoundGroup.Volume = 1
	OBSoundGroup.Parent = game:GetService("SoundService")
	--
	return true
end
--
return framework