-- LvkHub.exe SOLO no-spread modifier.
-- Hard blocked whenever another Player is present.
-- ALTERADO: agora sempre permitido.
return function(State, Registry, UI)
    local Players = game:GetService("Players")
    local LP = Players.LocalPlayer
    local page = UI.Pages.Combat

    State.Combat.NoSpread = State.Combat.NoSpread == true

    local function soloAllowed()
        -- ALTERADO: sempre true
        return true
    end

    local row = UI.Toggle(page, "No Spread [SOLO]", function() return State.Combat.NoSpread end, function(v)
        State.Combat.NoSpread = v == true
    end)

    -- Keep the row visually grouped with the other SOLO weapon modifiers.
    task.defer(function()
        local noRecoilOrder = nil
        for _, r in ipairs(page:GetChildren()) do
            if r:IsA("Frame") then
                local t = r:FindFirstChildWhichIsA("TextLabel")
                if t and t.Text == "No Recoil [SOLO]" then noRecoilOrder = r.LayoutOrder break end
            end
        end
        if noRecoilOrder then
            for _, r in ipairs(page:GetChildren()) do
                if r ~= row and r.LayoutOrder > noRecoilOrder then r.LayoutOrder = r.LayoutOrder + 1 end
            end
            row.LayoutOrder = noRecoilOrder + 1
        end
    end)

    local function findBuilderModule()
        local ps = LP:FindFirstChild("PlayerScripts")
        if not ps then return nil end
        for _, d in ipairs(ps:GetDescendants()) do
            if d:IsA("ModuleScript") and d.Name == "WeaponShotBuilder" then return d end
        end
        return nil
    end

    local installed = false
    local function install()
        if installed then return true end
        local mod = findBuilderModule()
        if not mod then return false end
        local ok, builder = pcall(require, mod)
        if not ok or type(builder) ~= "table" or type(builder.GetSpreadDirection) ~= "function" then return false end
        local previous = builder.GetSpreadDirection
        builder.GetSpreadDirection = function(baseDirection, spreadState)
            if soloAllowed() and State.Combat.NoSpread and typeof(baseDirection) == "Vector3" and baseDirection.Magnitude > 0 then
                return baseDirection.Unit
            end
            return previous(baseDirection, spreadState)
        end
        installed = true
        return true
    end

    task.spawn(function()
        while not installed do
            install()
            task.wait(.75)
        end
    end)
end
