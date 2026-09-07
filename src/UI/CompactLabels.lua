-- Shortens long row labels so sliders/value badges do not overlap text.
return function(State, UI)
    local replacements={
        ["Reload Multiplier"]="Reload Mult.",
        ["Self Transparency"]="Self Transp.",
        ["Gun Transparency"]="Gun Transp.",
        ["Car ESP Transparency"]="Car ESP Transp.",
        ["Trail Thickness"]="Trail Thick.",
        ["Trail Lifetime"]="Trail Life",
        ["Fast Reload Multiplier"]="Fast Reload Mult.",
        ["FOV Radius"]="FOV Radius",
        ["HitBox Size"]="HitBox Size",
    }

    local function apply()
        for _,page in pairs(UI.Pages) do
            for _,obj in ipairs(page:GetDescendants()) do
                if obj:IsA("TextLabel") then
                    local new=replacements[obj.Text]
                    if new then obj.Text=new end
                end
            end
        end
    end

    task.defer(apply)
    task.delay(.35,apply)
    task.delay(1,apply)
end
