-- Local TestPlayers fallback: plays HitSound when the center ray intersects a managed practice dummy.
return function(State, Registry, UI)
    local UIS=game:GetService("UserInputService")
    local Workspace=game:GetService("Workspace")
    local Players=game:GetService("Players")
    local LP=Players.LocalPlayer

    local function dummyFrom(inst)
        local cur=inst
        while cur and cur~=Workspace do
            if cur:IsA("Model") and Registry.IsBot(cur) then return cur end
            cur=cur.Parent
        end
    end

    UIS.InputBegan:Connect(function(input,_processed)
        if input.UserInputType~=Enum.UserInputType.MouseButton1 then return end
        if not State.Local.HitSound then return end
        local cam=Workspace.CurrentCamera
        if not cam then return end
        local center=cam.ViewportSize/2
        local ray=cam:ViewportPointToRay(center.X,center.Y)
        local params=RaycastParams.new()
        params.FilterType=Enum.RaycastFilterType.Exclude
        local ex={cam}
        if LP.Character then table.insert(ex,LP.Character) end
        params.FilterDescendantsInstances=ex
        params.IgnoreWater=true
        local hit=Workspace:Raycast(ray.Origin,ray.Direction*20000,params)
        if hit and dummyFrom(hit.Instance) and shared.LvkHubPlayHitSound then
            task.defer(shared.LvkHubPlayHitSound)
        end
    end)
end
