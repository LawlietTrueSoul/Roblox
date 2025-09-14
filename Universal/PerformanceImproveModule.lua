-- This one is totally scripted by GPT-5 Pro

local Players            = game:GetService("Players")
local RunService         = game:GetService("RunService")
local Lighting           = game:GetService("Lighting")
local Workspace          = game:GetService("Workspace")
local UserInputService   = game:GetService("UserInputService")

local LP = Players.LocalPlayer

-- ==== CẤU HÌNH ====
local CFG = {
	-- UltraLow
	killPostEffects      = true,
	lowerAtmosphere      = true,
	killParticles        = true,
	killBeamsAndTrails   = true,
	killShadowsOnParts   = true,
	useHeavyFog          = true,
	fogEnd               = 200,
	killDecalsTextures   = true,   -- UltraLow: ẩn Decal/Texture (Transparency=1), KHÔNG xoá
	watchNewDescendants  = true,
	log                  = true,

	-- Purple Fog
	enablePurpleOnStart  = false,

	-- Brutal
	brutalDestroyDecalsTextures = true, -- Brutal: XOÁ hẳn Decal/Texture
	brutalDestroyParticles      = true, -- Brutal: XOÁ hẳn Particle/Trail
	brutalForceMaterials        = true, -- Brutal: ép Material/Reflectance/CastShadow

	-- Phím nóng
	toggleUltraKey       = Enum.KeyCode.F7,
	toggleBrutalKey      = Enum.KeyCode.F8,
	togglePurpleKey      = Enum.KeyCode.F6,
	toggle3DKey          = Enum.KeyCode.F10,

	-- Whitelist theo tên (đừng đụng)
	nameWhitelist        = {
		--["ImportantFX"] = true,
	},
}

-- ==== BIẾN TRẠNG-THÁI ====
local state = {
	ultraOn       = false,
	brutalOn      = false,
	purpleOn      = false,

	disabledCount = 0,
	connections   = {},

	stash = {
		-- UltraLow
		postEffects   = {},  -- inst -> prevEnabled
		atmosphere    = nil, -- {inst=Atmosphere, props={...}}
		lighting      = {},  -- Fog/Shadow/EnvScale
		effects       = {},  -- inst -> prevEnabled
		partsShadow   = {},  -- part -> prevCastShadow
		decals        = {},  -- inst -> prevTransparency

		-- Purple Fog
		lightingFog   = nil, -- {FogColor, FogStart, FogEnd, Brightness, OutdoorAmbient}
		atmDestroyed  = nil, -- true nếu đã phá Atmosphere (Purple)

		-- Brutal (reversible phần thuộc-tính; không thể hồi thứ đã Destroy)
		partProps     = {},  -- BasePart -> {Material, Reflectance, CastShadow}
	},
}

local function log(fmt, ...)
	if CFG.log then print("[FPSBooster] "..string.format(fmt, ...)) end
end

local function safeSet(inst, prop, val)
	local ok, err = pcall(function() inst[prop] = val end)
	if not ok and CFG.log then
		warn(("[FPSBooster] Không set được %s.%s: %s"):format(inst.ClassName, prop, tostring(err)))
	end
	return ok
end

local function isWhitelisted(inst)
	return inst and CFG.nameWhitelist[inst.Name] == true
end

local function killPostEffects()
	for _, child in ipairs(Lighting:GetChildren()) do
		if child:IsA("PostEffect") and not isWhitelisted(child) then
			state.stash.postEffects[child] = child.Enabled
			if child.Enabled then
				child.Enabled = false
				state.disabledCount += 1
			end
		end
	end
end

local function lowerAtmos()
	local atm = Lighting:FindFirstChildOfClass("Atmosphere")
	if not atm then return end
	state.stash.atmosphere = {
		inst = atm,
		props = {
			Density = atm.Density,
			Haze    = atm.Haze    or 0,
			Glare   = atm.Glare   or 0,
			Offset  = atm.Offset  or 0,
		}
	}
	safeSet(atm, "Density", 0)
	safeSet(atm, "Haze", 0)
	safeSet(atm, "Glare", 0)
	safeSet(atm, "Offset", 0)
end

local function lightenLighting()
	state.stash.lighting = {
		GlobalShadows = Lighting.GlobalShadows,
		ShadowSoftness = Lighting.ShadowSoftness,
		FogStart = Lighting.FogStart,
		FogEnd = Lighting.FogEnd,
		EnvironmentDiffuseScale  = Lighting.EnvironmentDiffuseScale,
		EnvironmentSpecularScale = Lighting.EnvironmentSpecularScale,
	}
	safeSet(Lighting, "GlobalShadows", false)
	safeSet(Lighting, "ShadowSoftness", 0)
	safeSet(Lighting, "EnvironmentDiffuseScale", 0)
	safeSet(Lighting, "EnvironmentSpecularScale", 0)

	if CFG.useHeavyFog and typeof(CFG.fogEnd) == "number" then
		safeSet(Lighting, "FogStart", 0)
		safeSet(Lighting, "FogEnd", math.max(16, CFG.fogEnd))
	end
end

local function killEffectInstance(inst)
	if isWhitelisted(inst) then return end
	if inst:IsA("ParticleEmitter") or inst:IsA("Beam") or inst:IsA("Trail")
		or inst:IsA("Smoke") or inst:IsA("Fire") or inst:IsA("Sparkles") then
		if state.stash.effects[inst] == nil then
			local prev = (inst.Enabled ~= nil) and inst.Enabled or false
			state.stash.effects[inst] = prev
			if prev then
				safeSet(inst, "Enabled", false)
				state.disabledCount += 1
			end
		end
	end
end

local function sweepEffects(root)
	for _, d in ipairs(root:GetDescendants()) do
		killEffectInstance(d)
	end
end

local function killPartShadow(inst)
	if isWhitelisted(inst) then return end
	if inst:IsA("BasePart") then
		if state.stash.partsShadow[inst] == nil then
			state.stash.partsShadow[inst] = inst.CastShadow
			if inst.CastShadow then
				safeSet(inst, "CastShadow", false)
				state.disabledCount += 1
			end
		end
	end
end

local function sweepPartShadows(root)
	for _, d in ipairs(root:GetDescendants()) do
		killPartShadow(d)
	end
end

local function hideDecalTexture(inst)
	if isWhitelisted(inst) then return end
	if inst:IsA("Decal") or inst:IsA("Texture") then
		if state.stash.decals[inst] == nil then
			state.stash.decals[inst] = inst.Transparency
			if inst.Transparency < 1 then
				safeSet(inst, "Transparency", 1)
				state.disabledCount += 1
			end
		end
	end
end

local function sweepHideDecals(root)
	for _, d in ipairs(root:GetDescendants()) do
		hideDecalTexture(d)
	end
end

local function setPurpleFog(on)
	if on then
		if not state.stash.lightingFog then
			state.stash.lightingFog = {
				FogColor = Lighting.FogColor,
				FogStart = Lighting.FogStart,
				FogEnd   = Lighting.FogEnd,
				Brightness = Lighting.Brightness,
				OutdoorAmbient = Lighting.OutdoorAmbient,
			}
		end
		safeSet(Lighting, "FogColor", Color3.fromRGB(128, 0, 255))
		safeSet(Lighting, "FogStart", 0)
		safeSet(Lighting, "FogEnd", 100)
		safeSet(Lighting, "Brightness", 1)
		safeSet(Lighting, "OutdoorAmbient", Color3.fromRGB(64, 0, 128))

		local atm = Lighting:FindFirstChildOfClass("Atmosphere")
		if atm then
			atm:Destroy()
			state.stash.atmDestroyed = true
		end
		state.purpleOn = true
		log("Purple Fog: ON")
	else
		if state.stash.lightingFog then
			for k, v in pairs(state.stash.lightingFog) do
				safeSet(Lighting, k, v)
			end
			state.stash.lightingFog = nil
		end
		state.purpleOn = false
		log("Purple Fog: OFF")
	end
end

local function brutalTouchInstance(inst)
	if isWhitelisted(inst) then return end

	if CFG.brutalDestroyDecalsTextures and (inst:IsA("Texture") or inst:IsA("Decal")) then
		inst:Destroy()
		return
	end
	if CFG.brutalDestroyParticles and (inst:IsA("ParticleEmitter") or inst:IsA("Trail")) then
		inst:Destroy()
		return
	end

	if CFG.brutalForceMaterials and inst:IsA("BasePart") then
		if not state.stash.partProps[inst] then
			state.stash.partProps[inst] = {
				Material = inst.Material,
				Reflectance = inst.Reflectance,
				CastShadow = inst.CastShadow,
			}
		end
		safeSet(inst, "Material", Enum.Material.SmoothPlastic)
		safeSet(inst, "Reflectance", 0)
		if inst.CastShadow then safeSet(inst, "CastShadow", false) end
	end
end

local function brutalSweep(root)
	for _, d in ipairs(root:GetDescendants()) do
		brutalTouchInstance(d)
	end
	pcall(function()
		game:GetService("UserSettings"):GetService("UserGameSettings").SavedQualityLevel = Enum.SavedQualitySetting.QualityLevel1
	end)
end

local function brutalRestore()
	for part, props in pairs(state.stash.partProps) do
		if part and part.Parent then
			for k, v in pairs(props) do safeSet(part, k, v) end
		end
	end
	state.stash.partProps = {}
end

-- ==== THEO-DÕI THỨ MỚI SINH RA ====
local function clearConnections()
	for _, conn in ipairs(state.connections) do
		if conn and conn.Disconnect then conn:Disconnect() end
	end
	state.connections = {}
end

local function hookDescendantWatchers()
	if not CFG.watchNewDescendants then return end
	clearConnections()

	table.insert(state.connections, Workspace.DescendantAdded:Connect(function(inst)
		if state.ultraOn then
			if CFG.killParticles or CFG.killBeamsAndTrails then
				killEffectInstance(inst)
			end
			if CFG.killShadowsOnParts then
				killPartShadow(inst)
			end
			if CFG.killDecalsTextures then
				hideDecalTexture(inst)
			end
		end
		if state.brutalOn then
			brutalTouchInstance(inst)
		end
	end))

	-- Lighting (post-process mới sinh)
	table.insert(state.connections, Lighting.ChildAdded:Connect(function(inst)
		if state.ultraOn and CFG.killPostEffects and inst:IsA("PostEffect") and not isWhitelisted(inst) then
			state.stash.postEffects[inst] = inst.Enabled
			if inst.Enabled then inst.Enabled = false end
		end
	end))
end

-- ==== ULTRALOW: ÁP DỤNG / PHỤC HỒI ====
local function applyUltra()
	if state.ultraOn then return end
	state.ultraOn = true
	state.disabledCount = 0

	if CFG.killPostEffects then killPostEffects() end
	if CFG.lowerAtmosphere then lowerAtmos() end
	lightenLighting()
	if CFG.killParticles or CFG.killBeamsAndTrails then sweepEffects(Workspace) end
	if CFG.killShadowsOnParts then sweepPartShadows(Workspace) end
	if CFG.killDecalsTextures then sweepHideDecals(Workspace) end

	hookDescendantWatchers()
	log("UltraLow: vô-hiệu %d đối tượng nặng.", state.disabledCount)
end

local function restoreUltra()
	if not state.ultraOn then return end
	state.ultraOn = false

	for inst, prev in pairs(state.stash.postEffects) do
		if inst and inst.Parent then safeSet(inst, "Enabled", prev) end
	end
	state.stash.postEffects = {}

	if state.stash.atmosphere and state.stash.atmosphere.inst and state.stash.atmosphere.inst.Parent then
		local atm = state.stash.atmosphere.inst
		for k, v in pairs(state.stash.atmosphere.props) do safeSet(atm, k, v) end
	end
	state.stash.atmosphere = nil

	for prop, val in pairs(state.stash.lighting) do safeSet(Lighting, prop, val) end
	state.stash.lighting = {}

	for inst, prev in pairs(state.stash.effects) do
		if inst and inst.Parent and inst.Enabled ~= nil then safeSet(inst, "Enabled", prev) end
	end
	state.stash.effects = {}

	for part, prev in pairs(state.stash.partsShadow) do
		if part and part.Parent then safeSet(part, "CastShadow", prev) end
	end
	state.stash.partsShadow = {}

	for inst, prev in pairs(state.stash.decals) do
		if inst and inst.Parent then safeSet(inst, "Transparency", prev) end
	end
	state.stash.decals = {}

	clearConnections()
	log("UltraLow: khôi phục xong.")
end

-- ==== BRUTAL: ÁP DỤNG / PHỤC HỒI ====
local function applyBrutal()
	if state.brutalOn then return end
	-- Brutal nên chạy sau/bên trên Ultra để chắc chắn tối giản
	if not state.ultraOn then applyUltra() end

	state.brutalOn = true
	brutalSweep(Workspace)
	hookDescendantWatchers()
	log("Brutal: đã xoá hiệu-ứng & ép vật-liệu. Lưu ý: nội dung đã Destroy sẽ không khôi phục.")
end

local function restoreBrutal()
	if not state.brutalOn then return end
	state.brutalOn = false
	brutalRestore()
	hookDescendantWatchers()
	log("Brutal: khôi phục thuộc-tính part (không thể phục hồi vật-thể đã Destroy).")
end

local function applyOtherScript()
    local sethiddenproperty = sethiddenproperty
    local Lighting = game:GetService("Lighting")
    local Terrain = workspace.Terrain

    if settings then
        local RenderSettings = settings():GetService("RenderSettings")
        local UserGameSettings = UserSettings():GetService("UserGameSettings")

        RenderSettings.EagerBulkExecution = false
        RenderSettings.QualityLevel = Enum.QualityLevel.Level01
        RenderSettings.MeshPartDetailLevel = Enum.MeshPartDetailLevel.Level01
        UserGameSettings.SavedQualityLevel = Enum.SavedQualitySetting.QualityLevel1
        workspace.InterpolationThrottling = Enum.InterpolationThrottlingMode.Enabled
    end


    Lighting.GlobalShadows = false
    Lighting.FogEnd = 1e9

    if sethiddenproperty then
        pcall(sethiddenproperty, Lighting, "Technology", Enum.Technology.Compatibility)
    end

    workspace.LevelOfDetail = Enum.ModelLevelOfDetail.Disabled

    Terrain.WaterWaveSize = 0
    Terrain.WaterWaveSpeed = 0
    Terrain.WaterReflectance = 0
    Terrain.WaterTransparency = 0

    if sethiddenproperty then
        sethiddenproperty(Terrain, "Decoration", false)
    end

    for Index, Object in ipairs(game:GetDescendants()) do
        if Object:IsA("Sky") then
            Object.StarCount = 0
            Object.CelestialBodiesShown = false
        elseif Object:IsA("BasePart") then
            Object.Material = "SmoothPlastic"
        elseif Object:IsA("BasePart") then
            Object.CastShadow = false
        elseif Object:IsA("Atmosphere") then
            Object.Density = 0
            Object.Offset = 0
            Object.Glare = 0
            Object.Haze = 0
        elseif Object:IsA("SurfaceAppearance") then
            Object:Destroy()
        elseif (Object:IsA("Decal") or Object:IsA("Texture")) and string.lower(Object.Parent.Name) ~= "head" then
            Object.Transparency = 1
        elseif (Object:IsA("ParticleEmitter") or Object:IsA("Sparkles") or Object:IsA("Smoke") or Object:IsA("Trail") or Object:IsA("Fire")) then
            Object.Enabled = false
        elseif (Object:IsA("ColorCorrectionEffect") or Object:IsA("DepthOfFieldEffect") or Object:IsA("SunRaysEffect") or Object:IsA("BloomEffect") or Object:IsA("BlurEffect")) then
            Object.Enabled = false
        end
    end
end
local function Returned()
    applyUltra()
    applyBrutal()
    applyOtherScript()
end


return Returned
