-- Restores the blue/periwinkle accent used by the older Yokai visuals.
-- Also guards dynamically repainted toggle/scrollbar elements so the old purple does not return.

return function(UI)
    local BLUE=Color3.fromRGB(119,120,255)
    local OLD=Color3.fromRGB(125,82,235)
    UI.Accent=BLUE

    local guarded=setmetatable({}, {__mode="k"})
    local function same(a,b)
        return math.abs(a.R-b.R)<0.002 and math.abs(a.G-b.G)<0.002 and math.abs(a.B-b.B)<0.002
    end
    local function apply(obj)
        if not obj or guarded[obj] then return end
        guarded[obj]=true

        if obj:IsA("GuiObject") then
            if same(obj.BackgroundColor3,OLD) then obj.BackgroundColor3=BLUE end
            obj:GetPropertyChangedSignal("BackgroundColor3"):Connect(function()
                if obj.Parent and same(obj.BackgroundColor3,OLD) then obj.BackgroundColor3=BLUE end
            end)
        end
        if obj:IsA("ScrollingFrame") then
            if same(obj.ScrollBarImageColor3,OLD) then obj.ScrollBarImageColor3=BLUE end
            obj:GetPropertyChangedSignal("ScrollBarImageColor3"):Connect(function()
                if obj.Parent and same(obj.ScrollBarImageColor3,OLD) then obj.ScrollBarImageColor3=BLUE end
            end)
        end
        if obj:IsA("UIStroke") then
            if same(obj.Color,OLD) then obj.Color=BLUE end
            obj:GetPropertyChangedSignal("Color"):Connect(function()
                if obj.Parent and same(obj.Color,OLD) then obj.Color=BLUE end
            end)
        end
    end

    apply(UI.Gui)
    for _,d in ipairs(UI.Gui:GetDescendants()) do apply(d) end
    UI.Gui.DescendantAdded:Connect(function(d) task.defer(apply,d) end)
end
