-- LvkHub.exe Utility presets + configurable menu key.
-- Presets store menu state/settings only; target/session restrictions remain enforced elsewhere.
return function(State, Registry, UI)
    local UIS=game:GetService("UserInputService")
    local HttpService=game:GetService("HttpService")
    local page=UI.Pages.Utility
    if not page then return end

    State.Utility=State.Utility or {}
    State.Utility.MenuKeyName=State.Utility.MenuKeyName or "RightShift"
    State.Keybinds=State.Keybinds or {}

    local ROOT="LvkHub"
    local DIR=ROOT.."/Presets"
    shared.LvkHubPresetMemory=shared.LvkHubPresetMemory or {}
    local memory=shared.LvkHubPresetMemory

    local function rounded(obj,r)
        local c=Instance.new("UICorner")
        c.CornerRadius=UDim.new(0,r or 4)
        c.Parent=obj
    end

    local function fileBackend()
        return type(writefile)=="function" and type(readfile)=="function"
    end

    local function ensureFolders()
        if not fileBackend() then return false end
        pcall(function()
            if type(isfolder)=="function" and type(makefolder)=="function" then
                if not isfolder(ROOT) then makefolder(ROOT) end
                if not isfolder(DIR) then makefolder(DIR) end
            elseif type(makefolder)=="function" then
                pcall(makefolder,ROOT)
                pcall(makefolder,DIR)
            end
        end)
        return true
    end

    local function cleanName(s)
        s=tostring(s or ""):gsub("^%s+",""):gsub("%s+$","")
        s=s:gsub("[^%w_%-%s]","")
        s=s:gsub("%s+","_")
        if s=="" then s="preset" end
        return s:sub(1,40)
    end

    local function encodeValue(v,seen)
        local tv=type(v)
        local kind=typeof(v)
        if tv=="nil" or tv=="number" or tv=="string" or tv=="boolean" then return v end
        if kind=="Color3" then return {__lvkType="Color3",r=v.R,g=v.G,b=v.B} end
        if kind=="Vector2" then return {__lvkType="Vector2",x=v.X,y=v.Y} end
        if kind=="Vector3" then return {__lvkType="Vector3",x=v.X,y=v.Y,z=v.Z} end
        if kind=="UDim2" then return {__lvkType="UDim2",xs=v.X.Scale,xo=v.X.Offset,ys=v.Y.Scale,yo=v.Y.Offset} end
        if kind=="EnumItem" then return {__lvkType="EnumItem",enum=tostring(v.EnumType),name=v.Name} end
        if kind=="Instance" or tv=="function" or tv=="thread" or tv=="userdata" then return nil end
        if tv~="table" then return nil end
        seen=seen or {}
        if seen[v] then return nil end
        seen[v]=true
        local out={}
        for k,val in pairs(v) do
            if type(k)=="string" or type(k)=="number" then
                local enc=encodeValue(val,seen)
                if enc~=nil then out[k]=enc end
            end
        end
        seen[v]=nil
        return out
    end

    local function decodeValue(v)
        if type(v)~="table" then return v end
        local tag=v.__lvkType
        if tag=="Color3" then return Color3.new(tonumber(v.r) or 0,tonumber(v.g) or 0,tonumber(v.b) or 0) end
        if tag=="Vector2" then return Vector2.new(tonumber(v.x) or 0,tonumber(v.y) or 0) end
        if tag=="Vector3" then return Vector3.new(tonumber(v.x) or 0,tonumber(v.y) or 0,tonumber(v.z) or 0) end
        if tag=="UDim2" then return UDim2.new(tonumber(v.xs) or 0,tonumber(v.xo) or 0,tonumber(v.ys) or 0,tonumber(v.yo) or 0) end
        if tag=="EnumItem" then
            local enumName=tostring(v.enum or ""):gsub("^Enum%.","")
            local enumType=Enum[enumName]
            if enumType and v.name and enumType[v.name] then return enumType[v.name] end
            return nil
        end
        local out={}
        for k,val in pairs(v) do
            if k~="__lvkType" then out[k]=decodeValue(val) end
        end
        return out
    end

    local SAVE_KEYS={"Visuals","World","Movement","Combat","Utility","Local","Keybinds"}
    local function snapshot()
        local out={version=1}
        for _,k in ipairs(SAVE_KEYS) do
            if type(State[k])=="table" then out[k]=encodeValue(State[k],{}) end
        end
        return out
    end

    local function mergeInto(dst,src)
        if type(dst)~="table" or type(src)~="table" then return end
        for k,v in pairs(src) do
            if type(v)=="table" and v.__lvkType==nil and type(dst[k])=="table" then
                mergeInto(dst[k],v)
            else
                local decoded=decodeValue(v)
                if decoded~=nil then dst[k]=decoded end
            end
        end
    end

    local function applySnapshot(data)
        if type(data)~="table" then return false,"invalid preset" end
        for _,k in ipairs(SAVE_KEYS) do
            local src=data[k]
            if type(src)=="table" then
                State[k]=State[k] or {}
                if k=="Keybinds" then table.clear(State[k]) end
                mergeInto(State[k],src)
            end
        end
        State.Utility.MenuKeyName=State.Utility.MenuKeyName or "RightShift"
        if UI.RefreshAll then UI.RefreshAll() end
        return true
    end

    local function presetPath(name)
        return DIR.."/"..cleanName(name)..".json"
    end

    local function writePreset(name)
        name=cleanName(name)
        local data=snapshot()
        local ok,json=pcall(function() return HttpService:JSONEncode(data) end)
        if not ok then return false,"encode failed" end
        memory[name]=json
        if fileBackend() then
            ensureFolders()
            local wrote,err=pcall(writefile,presetPath(name),json)
            if not wrote then return false,tostring(err) end
        end
        return true,name
    end

    local function readPreset(name)
        name=cleanName(name)
        local json=memory[name]
        if fileBackend() then
            ensureFolders()
            local path=presetPath(name)
            local exists=true
            if type(isfile)=="function" then
                local ok,res=pcall(isfile,path)
                exists=ok and res==true
            end
            if exists then
                local ok,res=pcall(readfile,path)
                if ok and type(res)=="string" then json=res end
            end
        end
        if type(json)~="string" then return nil,"preset not found" end
        local ok,data=pcall(function() return HttpService:JSONDecode(json) end)
        if not ok then return nil,"decode failed" end
        return data
    end

    local function deletePreset(name)
        name=cleanName(name)
        memory[name]=nil
        if fileBackend() and type(delfile)=="function" then
            local path=presetPath(name)
            pcall(function()
                if type(isfile)~="function" or isfile(path) then delfile(path) end
            end)
        end
    end

    local function listPresets()
        local set={}
        for name in pairs(memory) do set[name]=true end
        if fileBackend() and type(listfiles)=="function" then
            ensureFolders()
            local ok,files=pcall(listfiles,DIR)
            if ok and type(files)=="table" then
                for _,path in ipairs(files) do
                    local name=tostring(path):match("([^/\\]+)%.json$")
                    if name then set[name]=true end
                end
            end
        end
        local out={}
        for name in pairs(set) do table.insert(out,name) end
        table.sort(out,function(a,b) return a:lower()<b:lower() end)
        return out
    end

    ------------------------------------------------------------------------
    -- MENU KEY
    ------------------------------------------------------------------------
    UI.Section(page,"Menu")
    local menuRow,menuLabel=UI.Row(page,"Menu Key")
    menuLabel.Size=UDim2.new(1,-102,1,0)
    local menuButton=Instance.new("TextButton")
    menuButton.AnchorPoint=Vector2.new(1,.5)
    menuButton.Position=UDim2.new(1,-7,.5,0)
    menuButton.Size=UDim2.fromOffset(88,20)
    menuButton.BackgroundColor3=Color3.fromRGB(37,38,46)
    menuButton.BorderSizePixel=0
    menuButton.Font=Enum.Font.Code
    menuButton.TextSize=10
    menuButton.TextColor3=Color3.fromRGB(220,220,228)
    menuButton.Parent=menuRow
    rounded(menuButton,3)

    local listening=false
    local function paintMenuKey()
        menuButton.Text=listening and "PRESS KEY" or tostring(State.Utility.MenuKeyName or "RightShift")
        menuButton.TextColor3=listening and UI.Accent or Color3.fromRGB(220,220,228)
    end
    menuButton.MouseButton1Click:Connect(function() listening=true; paintMenuKey() end)
    paintMenuKey()

    UIS.InputBegan:Connect(function(input)
        if not listening then return end
        if input.KeyCode==Enum.KeyCode.Unknown then return end
        if input.KeyCode==Enum.KeyCode.Escape then
            listening=false
        elseif input.KeyCode==Enum.KeyCode.Backspace or input.KeyCode==Enum.KeyCode.Delete then
            State.Utility.MenuKeyName="RightShift"
            listening=false
        else
            State.Utility.MenuKeyName=input.KeyCode.Name
            listening=false
        end
        paintMenuKey()
    end)

    UI.Button(page,"Reset menu key","RESET",function()
        State.Utility.MenuKeyName="RightShift"
        listening=false
        paintMenuKey()
    end)

    ------------------------------------------------------------------------
    -- PRESETS
    ------------------------------------------------------------------------
    UI.Section(page,"Presets")
    local nameRow,nameLabel=UI.Row(page,"Preset name")
    nameLabel.Size=UDim2.new(1,-104,1,0)
    local nameBox=Instance.new("TextBox")
    nameBox.AnchorPoint=Vector2.new(1,.5)
    nameBox.Position=UDim2.new(1,-7,.5,0)
    nameBox.Size=UDim2.fromOffset(90,20)
    nameBox.BackgroundColor3=Color3.fromRGB(32,32,36)
    nameBox.BorderSizePixel=0
    nameBox.ClearTextOnFocus=false
    nameBox.PlaceholderText="preset"
    nameBox.Text=""
    nameBox.Font=Enum.Font.SourceSans
    nameBox.TextSize=11
    nameBox.TextColor3=Color3.fromRGB(220,220,228)
    nameBox.PlaceholderColor3=Color3.fromRGB(110,115,128)
    nameBox.Parent=nameRow
    rounded(nameBox,3)

    local selected=nil
    local names={}
    local index=0
    local selectRow,selectLabel=UI.Row(page,"Saved preset: none")
    selectLabel.Size=UDim2.new(1,-82,1,0)
    selectLabel.TextSize=12
    local nextButton=Instance.new("TextButton")
    nextButton.AnchorPoint=Vector2.new(1,.5)
    nextButton.Position=UDim2.new(1,-7,.5,0)
    nextButton.Size=UDim2.fromOffset(68,20)
    nextButton.BackgroundColor3=Color3.fromRGB(37,38,46)
    nextButton.BorderSizePixel=0
    nextButton.Font=Enum.Font.SourceSansSemibold
    nextButton.TextSize=11
    nextButton.TextColor3=Color3.fromRGB(215,215,224)
    nextButton.Text="NEXT"
    nextButton.Parent=selectRow
    rounded(nextButton,3)

    local _,status=UI.Row(page,"Preset storage: checking...",38)
    status.TextSize=11
    status.TextColor3=Color3.fromRGB(145,150,170)
    status.TextWrapped=true

    local function refreshPresets(prefer)
        names=listPresets()
        if #names==0 then
            selected=nil; index=0; selectLabel.Text="Saved preset: none"
        else
            if prefer then
                local found=table.find(names,prefer)
                if found then index=found end
            end
            if index<1 or index>#names then index=1 end
            selected=names[index]
            selectLabel.Text="Saved: "..selected
        end
        status.Text=(fileBackend() and "Preset storage: persistent" or "Preset storage: session memory").." • "..tostring(#names).." saved"
    end

    nextButton.MouseButton1Click:Connect(function()
        refreshPresets()
        if #names==0 then return end
        index=index%#names+1
        selected=names[index]
        selectLabel.Text="Saved: "..selected
    end)

    UI.Button(page,"Save preset","SAVE",function(b)
        local name=cleanName(nameBox.Text~="" and nameBox.Text or selected or "preset")
        b.Text="..."
        local ok,res=writePreset(name)
        if ok then
            nameBox.Text=name
            refreshPresets(name)
            status.Text="Saved preset: "..name
        else status.Text="Save failed: "..tostring(res) end
        task.wait(.45); b.Text="SAVE"
    end)

    UI.Button(page,"Load selected","LOAD",function(b)
        if not selected then status.Text="No preset selected"; return end
        b.Text="..."
        local data,err=readPreset(selected)
        if data then
            local ok,msg=applySnapshot(data)
            status.Text=ok and ("Loaded preset: "..selected) or ("Load failed: "..tostring(msg))
            paintMenuKey()
        else status.Text="Load failed: "..tostring(err) end
        task.wait(.45); b.Text="LOAD"
    end)

    UI.Button(page,"Delete selected","DELETE",function(b)
        if not selected then status.Text="No preset selected"; return end
        local old=selected
        b.Text="..."
        deletePreset(old)
        index=1
        refreshPresets()
        status.Text="Deleted preset: "..old
        task.wait(.45); b.Text="DELETE"
    end)

    UI.Button(page,"Refresh presets","REFRESH",function(b)
        b.Text="..."
        refreshPresets(selected)
        task.wait(.35); b.Text="REFRESH"
    end)

    refreshPresets()
end
