--[[
    {
        COPYRIGHT: Lawliet

        The script is fully written by @phbaen on Discord

        My contact: { https://www.facebook.com/PhBaAnh }


        [ Remember son, SKID IS NIGG- ]
    }
]]




local isfolder = getgenv().isfolder
local makefolder = getgenv().makefolder
local writefile = getgenv().writefile
local readfile = getgenv().readfile
local isfile = getgenv().isfile


--// game instances
local plr = game.Players.LocalPlayer
local PlrGui = plr.PlayerGui
local VirtualInputManager = game:GetService("VirtualInputManager")


local function getService(s)
    return game:GetService(s)
end

local Settings = {
    SpeedHack = false,
    DisableHitSound = false,
    DisableAttackSound = false,
    FastAttack = false,
    ToggleFly = false,

    Save = function(self)
        if not isfolder("lawliet") then
            makefolder("lawliet")
        end
        
        if not isfolder("lawliet/Dungeon Quest/") then
            makefolder("lawliet/Dungeon Quest/")
        end

        local function jsonEncode (s)
            return getService("HttpService"):JSONEncode(s)
        end
        local temporary = {}
        for i, v in pairs(self) do
            if typeof(v) ~= "function" then
                temporary[i] = v
            end
        end
        writefile("lawliet/Dungeon Quest/" .. plr.Name .. ".json", jsonEncode(temporary))
    end,


    Load = function(self)
        local function jsonDecode (s)
            return getService("HttpService"):JSONDecode(s)
        end
        local fromWorkspace = jsonDecode(readfile("lawliet/Dungeon Quest/".. plr.Name .. ".json"))

        for i, v in pairs(fromWorkspace) do
            self[i] = v
        end
    end,

}

if isfile("lawliet/Dungeon Quest/".. plr.Name .. ".json") then
    local s, b = pcall(function() Settings:Load() end)
    if s then
        print("Successfully imported data from workspace")
    else
        print("Failed in importing data from workspace")
        Settings:Save()
    end
else
    Settings:Save()
end




local RCA = {
    OnDeath = function(self, Function)
        while true do
            local Humanoid = plr.Character:FindFirstChild("Humanoid")
            if Humanoid then
                return Humanoid.Died:Connect(Function)
            else
                wait(1)
            end
        end
    end,

    OnRespawn = function(self, Function)
        return plr.CharacterAdded:Connect(Function)
    end,

}


local scripts = {
	["Fly"] = {
		Function = function()
			local player = game.Players.LocalPlayer
			local character = player.Character or player.CharacterAdded:Wait()
			local rootPart = character:WaitForChild("HumanoidRootPart")

			local flying = false
			local flySpeed = 35

			local uis = game:GetService("UserInputService")

			local movementKeys = {
				W = false,
				A = false,
				S = false,
				D = false,
				Space = false,
				Control = false
			}

			getgenv().FlyConnection = {}

			local function startFlying()
				flying = true
				local bodyVelocity = Instance.new("BodyVelocity")
				bodyVelocity.MaxForce = Vector3.new(9e9, 9e9, 9e9)
				bodyVelocity.Velocity = Vector3.new(0, 0, 0)
				bodyVelocity.P = 9e9
				bodyVelocity.Parent = rootPart

				while flying do
					if getgenv().FlyConnection == nil then
						break
					end
					if movementKeys.W or movementKeys.A or movementKeys.S or movementKeys.D or movementKeys.Space or movementKeys.Control then
						local camera = workspace.CurrentCamera
						local direction = Vector3.new(0, 0, 0)

						if movementKeys.W then
							direction = direction + camera.CFrame.LookVector
						end
						if movementKeys.S then
							direction = direction - camera.CFrame.LookVector
						end
						if movementKeys.A then
							direction = direction - camera.CFrame.RightVector
						end
						if movementKeys.D then
							direction = direction + camera.CFrame.RightVector
						end
						if movementKeys.Space then
							direction = direction + Vector3.new(0, 1, 0)
						end
						if movementKeys.Control then
							direction = direction - Vector3.new(0, 1, 0)
						end

						bodyVelocity.Velocity = direction.Unit * flySpeed
					else
						bodyVelocity.Velocity = Vector3.new(0, 0, 0)
					end
					pcall(function()
						for i, v in pairs(plr.Character:GetChildren()) do
							if v:IsA("BasePart") then
								v.CanCollide = false
							end
						end
					end)
					wait()
				end

				bodyVelocity:Destroy()
			end

			local function stopFlying()
				flying = false
			end


			getgenv().FlyConnection[0] = uis.InputBegan:Connect(function(input)
				if input.KeyCode == Enum.KeyCode.F then  -- Nhấn F để bật/tắt bay
					if flying then
						stopFlying()
					else
						startFlying()
					end
				elseif input.KeyCode == Enum.KeyCode.W then
					movementKeys.W = true
				elseif input.KeyCode == Enum.KeyCode.A then
					movementKeys.A = true
				elseif input.KeyCode == Enum.KeyCode.S then
					movementKeys.S = true
				elseif input.KeyCode == Enum.KeyCode.D then
					movementKeys.D = true
				elseif input.KeyCode == Enum.KeyCode.Space then
					movementKeys.Space = true
				elseif input.KeyCode == Enum.KeyCode.LeftControl then
					movementKeys.Control = true
				end
			end)

			
			getgenv().FlyConnection[1] = uis.InputEnded:Connect(function(input)
				if input.KeyCode == Enum.KeyCode.W then
					movementKeys.W = false
				elseif input.KeyCode == Enum.KeyCode.A then
					movementKeys.A = false
				elseif input.KeyCode == Enum.KeyCode.S then
					movementKeys.S = false
				elseif input.KeyCode == Enum.KeyCode.D then
					movementKeys.D = false
				elseif input.KeyCode == Enum.KeyCode.Space then
					movementKeys.Space = false
				elseif input.KeyCode == Enum.KeyCode.LeftControl then
					movementKeys.Control = false
				end
			end)

		end,
		
		Load = function(self)
            self.Function()
		end,

        Unload = function()
            if getgenv().FlyConnection ~= nil then
				for i, v in pairs(getgenv().FlyConnection) do
					v:Disconnect()
				end
                getgenv().FlyConnection = nil
            end
        end
	},
    -- [[ ... ]] 
}


print('Loaded')



local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local Window = Fluent:CreateWindow({
    Title = "Dungeon Quest ToolKit",
    SubTitle = "by PhBaAnh",
    TabWidth = 100,
    Size = UDim2.fromOffset(500, 330),
    Acrylic = false,
    Theme = "Amethyst",
    MinimizeKey = Enum.KeyCode.M
})



local Tabs = {
    Main = Window:AddTab({ Title = "Main", Icon = "" }),
    Info = Window:AddTab({ Title = "Info", Icon = "" }),
}

Window:SelectTab(1)





do
    RCA:OnRespawn(function(char)
        if Settings.SpeedHack then
            char:WaitForChild("Humanoid").WalkSpeed = 35
        end
    end)

    Tabs.Main:AddToggle("se", {Title = "Speed Hack", Default = Settings.SpeedHack }):OnChanged(
        function(v)
            Settings.SpeedHack = v
            Settings:Save()

            if Settings.SpeedHack then
                spawn(function()
                    plr.Character:WaitForChild("Humanoid").WalkSpeed = 35
                end)
            else
                spawn(function()
                    plr.Character:WaitForChild("Humanoid").WalkSpeed = 16
                end)
            end
        end
    )
    
    local function Speeding()
        while wait() do
            if plr.Character then
                if Settings.SpeedHack then
                    plr.Character:WaitForChild("Humanoid").WalkSpeed = 35
                else
                    plr.Character:WaitForChild("Humanoid").WalkSpeed = 16
                end
            end
        end
    end
    spawn(Speeding)
end



do
    function get_weapon_accessory()
        if not plr.Character then return end
        if not workspace:FindFirstChild(plr.Name) then return end

        if not workspace[plr.Name]:FindFirstChild("WeaponGear") then
            return
        end

        for i, v in pairs(workspace[plr.Name].WeaponGear:GetChildren()) do
            if v:FindFirstChild("attackSpeed") then
                return v
            end
        end
    end

    RCA:OnRespawn(function(char)
        local weapon = nil
        while true do
            local v = get_weapon_accessory()
            if v then
                weapon = v
                break
            end
            wait()
        end
        
        if Settings.DisableAttackSound then
            weapon.Handle.swing.Volume = 0
        end
    end)
    Tabs.Main:AddToggle("asikoldfoasioi", { Title = "Disable Attack Sound", Default = Settings.DisableAttackSound }):OnChanged(
        function(v)
            Settings.DisableAttackSound = v
            Settings:Save()


            if Settings.DisableAttackSound then
                get_weapon_accessory().Handle.swing.Volume = 0
            else
                get_weapon_accessory().Handle.swing.Volume = 0.5
            end
        end
    )

    Tabs.Main:AddToggle("asdasd", { Title = "Disable Hit Sound", Default = Settings.DisableHitSound }):OnChanged(
        function(v)
            Settings.DisableHitSound = v
            Settings:Save()
            
            local obj = game:GetService("ReplicatedStorage").Assets.Sounds.Effects["Melee Hit"]
            if Settings.DisableHitSound then
                obj.Volume = 0
            else
                obj.Volume = 0.5
            end
        end
    )
end



local Nearby = false
do
    local function trackEnemyPosition()
        if plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then else
            return
        end

        for _, enemy in pairs(workspace.dungeon:GetDescendants()) do
            if not enemy:IsA("Model") then continue end

            if enemy:FindFirstChild("HumanoidRootPart") then
                local distance = (enemy.HumanoidRootPart.Position - plr.Character.HumanoidRootPart.Position).Magnitude
                if distance < 23 then
                    Nearby = true
                    return
                end
            end
        end

        Nearby = false
    end

    spawn(function()
        while wait() do
            trackEnemyPosition()
        end
    end)

    --// fast attack
    Tabs.Main:AddToggle("szdxfuahsiu", { Title = "Fast Attack", Default = Settings.FastAttack }):OnChanged(
        function(v)
            Settings.FastAttack = v
            Settings:Save()
        end
    )
end

spawn(function()
    local n =  1 / 10000
    local cwait = task.wait

    while cwait(n) do
        if not Settings.FastAttack then
            wait(0.5)
            continue
        end

        local weap = get_weapon_accessory()
        if weap then
            weap.attackSpeed.Value = 2000
        end

            -- Heartbeat:Wait()

        if Nearby then
            if workspace:FindFirstChild(plr.Name) then
                workspace[plr.Name].busyCasting.Value = false
            end
            VirtualInputManager:SendMouseButtonEvent(1, 1, 0, true, game, 1)
            VirtualInputManager:SendMouseButtonEvent(1, 1, 0, false, game, 1)
        end
    end
end)



do
    RCA:OnDeath(function()
        scripts.Fly:Unload()
    end)

    RCA:OnRespawn(function()
        if Settings.ToggleFly then
            scripts.Fly:Load()
        end
    end)
    Tabs.Main:AddToggle("aloksfikasmjik", { Title = "Toggle Fly [ F ]", Default = Settings.ToggleFly }):OnChanged(
        function(v)
            Settings.ToggleFly = v
            Settings:Save()

            if Settings.ToggleFly then
                scripts.Fly:Load()
            else
                scripts.Fly:Unload()
            end
        end
    )
end

Tabs.Info:AddButton({
    Title = "Copy Facebook Url",
    Description = "",
    Callback = function()
        setclipboard("https://www.facebook.com/PhBaAnh")
        Fluent:Notify({
            Title = "Notification",
            Content = "Successfully Copied",
            Duration = 5
        })
    end
})
