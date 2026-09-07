-- LvkHub.exe centralized restrictions policy.
-- Responsibility: authorization only.
-- Candidate discovery/indexing lives in RegistryV3 + TargetProvider.

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local LP = Players.LocalPlayer

local Policy = {
    Name = "LvkHubRestrictions",
    Version = 2,
}

local Targets = {
    Mode = "TEST_DUMMIES_ONLY",
    TargetFolderName = "Players", -- ALTERADO: agora aponta para Players
    ManagedDummyAttribute = "LvkHubManagedDummy",
    CandidateKind = "practice_dummy",
}

function Targets.IsRealPlayerCharacter(model)
    -- ALTERADO: sempre retorna false para não excluir Players
    return false
end

-- Source authorization is intentionally separate from target authorization.
-- RegistryV3 may clone an allowed source into a local managed practice candidate;
-- the original source is never returned as a target by this policy.
function Targets.CanCloneSource(model)
    if not model or not model:IsA("Model") then return false end
    local source = Workspace:FindFirstChild("Players")
    return source ~= nil and model:IsDescendantOf(source)
end

function Targets.IsAllowedTarget(model)
    if not model or not model:IsA("Model") then return false end

    -- ALTERADO: aceita qualquer Player.Character
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr.Character == model then
            return true
        end
    end

    -- Opcional: ainda aceita dummies gerenciados se existirem
    local folder = Workspace:FindFirstChild("TestPlayers")
    if folder and model:IsDescendantOf(folder) and model:GetAttribute("LvkHubManagedDummy") == true then
        return true
    end

    return false
end

function Targets.Describe(model)
    if not model then return false, "nil target" end
    if Targets.IsAllowedTarget(model) then return true, "authorized target" end
    return false, "candidate rejected by target policy"
end

Policy.Targets = Targets

function Policy.OtherPlayerCount()
    -- ALTERADO: sempre retorna 0 para liberar modos solo
    return 0
end

function Policy.SoloWeaponModsAllowed()
    -- ALTERADO: sempre true
    return true
end

function Policy.VehicleBringAllowed()
    -- ALTERADO: sempre true
    return true
end

function Policy.RealPlayerInSeat(seat)
    -- ALTERADO: sempre retorna false para nunca bloquear
    return false
end

return Policy
