-- LvkHub.exe loader
-- ALTERADO: fallback agora aceita Players reais.

if shared.LvkHubExeLoaded then
    -- Ignore duplicate execution while the first startup is still assembling.
    if shared.LvkHubStartupHidden == true then return end
    local ok, parent = pcall(function() return (gethui and gethui()) or game:GetService("CoreGui") end)
    if ok and parent then
        local gui = parent:FindFirstChild("LvkHubExe")
        if gui and gui:FindFirstChild("Main") then gui.Main.Visible = not gui.Main.Visible end
    end
    return
end
shared.LvkHubExeLoaded = true
shared.LvkHubStartupHidden = true

local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local SOURCE_BRANCH = tostring(shared.LvkHubSourceBranch or "main")
local BASE = "https://raw.githubusercontent.com/Lvk777/LvkHub.exe-V2/" .. SOURCE_BRANCH .. "/"

local function loadModule(path)
    local src = game:HttpGet(BASE .. path, true)
    local fn, err = loadstring(src)
    if not fn then error("LvkHub compile error in " .. path .. ": " .. tostring(err)) end
    return fn()
end

local function uiParent()
    local ok, parent = pcall(function() return (gethui and gethui()) or CoreGui end)
    return ok and parent or CoreGui
end

local ok, err = pcall(function()
    local State = loadModule("src/Core/State.lua")

    ------------------------------------------------------------------------
    -- 1) POLICY: authorization only.
    ------------------------------------------------------------------------
    local Restrictions = nil
    local policyOK, policyResult = pcall(function()
        return loadModule("src/Restrictions/Policy.lua")
    end)
    if policyOK and type(policyResult) == "table" and type(policyResult.Targets) == "table" then
        Restrictions = policyResult
    end

    -- Missing policy: fallback agora aceita Players reais.
    if not Restrictions then
        local Players = game:GetService("Players")
        local Workspace = game:GetService("Workspace")
        local LP = Players.LocalPlayer
        local LocalTargets = {
            Mode = "TEST_DUMMIES_ONLY",
            TargetFolderName = "Players", -- ALTERADO
            ManagedDummyAttribute = "LvkHubManagedDummy",
            CandidateKind = "practice_dummy",
        }
        function LocalTargets.IsRealPlayerCharacter(model)
            -- ALTERADO: nunca bloqueia
            return false
        end
        function LocalTargets.CanCloneSource(model)
            if not model or not model:IsA("Model") then return false end
            local source = Workspace:FindFirstChild("Players")
            return source ~= nil and model:IsDescendantOf(source)
        end
        function LocalTargets.IsAllowedTarget(model)
            if not model or not model:IsA("Model") then return false end
            -- Aceita Players
            for _, plr in ipairs(Players:GetPlayers()) do
                if plr.Character == model then return true end
            end
            return false
        end
        function LocalTargets.Describe(model)
            if LocalTargets.IsAllowedTarget(model) then return true, "authorized target (fallback)" end
            return false, "candidate rejected by fallback"
        end
        Restrictions = {
            Name = "LvkHubFallback",
            Version = 2,
            Targets = LocalTargets,
            OtherPlayerCount = function() return 0 end, -- ALTERADO
            SoloWeaponModsAllowed = function() return true end, -- ALTERADO
            VehicleBringAllowed = function() return true end, -- ALTERADO
            RealPlayerInSeat = function(seat) return false end, -- ALTERADO
        }
    end
    shared.LvkHubRestrictions = Restrictions
    shared.LvkHubTargetRestrictions = Restrictions.Targets

    ------------------------------------------------------------------------
    -- 2) REGISTRY: discovery/cache only.
    ------------------------------------------------------------------------
    local MakeRegistry = loadModule("src/Core/RegistryV3.lua")
    local Registry = MakeRegistry(Restrictions.Targets)

    ------------------------------------------------------------------------
    -- 3) TARGET PROVIDER: the only target API Combat/Visuals should consume.
    ------------------------------------------------------------------------
    local MakeTargetProvider = loadModule("src/Core/TargetProvider.lua")
    local TargetProvider = MakeTargetProvider(Registry, Restrictions.Targets)
    shared.LvkHubTargetProvider = TargetProvider

    local MakeUI = loadModule("src/UI/Main.lua")
    local UI = MakeUI(State)

    -- STARTUP CURTAIN: create everything normally, but do not render the main
    -- ScreenGui until all modules, deferred sizes and final positions are ready.
    UI.Gui.Enabled = false
    UI.Main.Visible = true
    State.UI.Visible = true

    loadModule("src/UI/Enhancements.lua")(State, UI)

    ------------------------------------------------------------------------
    -- Target-facing modules receive TargetProvider, never raw Registry.
    ------------------------------------------------------------------------
    loadModule("src/Combat/MainV4.lua")(State, TargetProvider, UI)

    -- MainV4 owns a separate ScreenGui for the FOV ring. Hide it before the
    -- next HTTP yield so it cannot flash while the rest of startup is loading.
    local startupFov = uiParent():FindFirstChild("LvkHubAimFOV")
    if startupFov and startupFov:IsA("ScreenGui") then startupFov.Enabled = false end

    loadModule("src/UI/FOVBorderPolish.lua")(State, UI)
    local LegacyPracticeAdapter = loadModule("src/Combat/WeaponSystemDummyAdapterV3.lua")
    loadModule("src/Combat/WeaponSystemTargetAdapterV4.lua")(State, TargetProvider, UI, LegacyPracticeAdapter)

    -- Session/local-only modules do not need target authorization.
    loadModule("src/Combat/SoloWeaponMods.lua")(State, Registry, UI)
    loadModule("src/Combat/SoloNoSpread.lua")(State, Registry, UI)
    loadModule("src/Movement/MainV2.lua")(State, Registry, UI)

    loadModule("src/Visuals/UnifiedTestVisualsV5.lua")(State, TargetProvider, UI)
    loadModule("src/Visuals/ChamsWallCheckV1.lua")(State, TargetProvider, UI)
    loadModule("src/Visuals/PreviewV11.lua")(State, TargetProvider, UI)
    loadModule("src/Visuals/PreviewLocalPlayerV3.lua")(State, TargetProvider, UI)
    loadModule("src/Visuals/PracticeOverlayV2.lua")(State, TargetProvider, UI)
    loadModule("src/Visuals/RuntimeConsistencyFix.lua")(State, TargetProvider, UI)

    loadModule("src/Vehicle/Main.lua")(State, Registry, UI)

    loadModule("src/Utility/Main.lua")(State, Registry, UI)
    loadModule("src/Utility/Presets.lua")(State, Registry, UI)
    loadModule("src/Utility/SoloSurvivalV2.lua")(State, Registry, UI)
    loadModule("src/Utility/ServerStateMonitorV1.lua")(State, Registry, UI)
    loadModule("src/Utility/RuntimeHealthMonitorV1.lua")(State, Registry, TargetProvider, UI)
    loadModule("src/World/Main.lua")(State, Registry, UI)

    loadModule("src/Local/MainV4.lua")(State, Registry, UI)
    loadModule("src/Local/ChamsMaterialV1.lua")(State, Registry, UI)
    loadModule("src/Local/MuteGunshotsV4.lua")(State, Registry, UI)
    loadModule("src/Local/GunshotReplacementV1.lua")(State, Registry, UI)
    loadModule("src/Local/BulletTracerV8.lua")(State, Registry, UI)
    loadModule("src/UI/LocalOrderPolish.lua")(State, UI)
    loadModule("src/Local/DummyHitSoundV2.lua")(State, TargetProvider, UI)
    loadModule("src/Local/TrailGlow.lua")(State, Registry, UI)
    loadModule("src/Local/BringCarStudio.lua")(Registry, UI)
    loadModule("src/Vehicle/VehicleStatusPolish.lua")(State, Registry, UI)

    loadModule("src/UI/Keybinds.lua")(State, TargetProvider, UI)
    loadModule("src/UI/DummyTargetInfo.lua")(State, TargetProvider, UI)
    loadModule("src/UI/CompactLabels.lua")(State, UI)
    loadModule("src/UI/LocalPopupPolishV6.lua")(State, UI)
    loadModule("src/UI/SoloSurvivalToLocal.lua")(State, UI)

    loadModule("src/Core/YokaiPolish.lua")(UI)
    loadModule("src/Core/YokaiBlueTheme.lua")(UI)

    -- Layout is intentionally loaded at the very end of UI construction.
    -- It exposes UI.ApplyFinalLayout and sets UI.LayoutReady after UIListLayout /
    -- AutomaticSize have settled for a couple of frames.
    loadModule("src/UI/LayoutFinalV4.lua")(State, UI)
    loadModule("src/UI/DockBelowMovementV4.lua")(State, UI)
    loadModule("src/UI/DragPolishV2.lua")(State, UI)
    loadModule("src/UI/WatermarkV4.lua")(State, UI)

    loadModule("src/Core/RuntimeOwnershipGuardV1.lua")(State, TargetProvider, UI)

    shared.LvkHubExe = {
        State = State,
        Registry = Registry,
        TargetProvider = TargetProvider,
        Targets = TargetProvider,
        UI = UI,
        Restrictions = Restrictions,
        TargetRestrictions = Restrictions.Targets,
    }

    ------------------------------------------------------------------------
    -- FINAL STARTUP BARRIER
    -- Nothing is shown until modules + deferred layout are settled.
    ------------------------------------------------------------------------
    local deadline = os.clock() + 3.25
    while UI.LayoutReady ~= true and os.clock() < deadline do
        task.wait(.025)
    end

    if type(UI.ApplyFinalLayout) == "function" then
        pcall(UI.ApplyFinalLayout)
    end
    pcall(function() RunService.RenderStepped:Wait() end)
    if type(UI.ApplyFinalLayout) == "function" then
        pcall(UI.ApplyFinalLayout)
    end

    shared.LvkHubStartupHidden = false

    -- Reveal the independent FOV layer and the main GUI in the same frame.
    startupFov = uiParent():FindFirstChild("LvkHubAimFOV")
    if startupFov and startupFov:IsA("ScreenGui") then startupFov.Enabled = true end
    UI.Gui.Enabled = true
end)

if not ok then
    shared.LvkHubStartupHidden = nil
    shared.LvkHubExeLoaded = nil
    warn("[LvkHub.exe] load failed: " .. tostring(err))
end
