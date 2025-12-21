-- ======================================================================
-- YBA AutoPrestige Fixed для Xeno Injector
-- Исправлены ошибки вызова nil функций
-- ======================================================================

getgenv().standList =  {
    ["The World"] = true,
    ["Star Platinum"] = true,
    ["Star Platinum: The World"] = true,
    ["Crazy Diamond"] = true,
    ["King Crimson"] = true,
    ["King Crimson Requiem"] = true
}
getgenv().waitUntilCollect = 0.5
getgenv().sortOrder = "Asc"
getgenv().lessPing = false
getgenv().autoRequiem = true
getgenv().NPCTimeOut = 15
getgenv().HamonCharge = 90
getgenv().webhook = ""

-- Безопасная обработка ошибок кика
game:GetService("CoreGui").DescendantAdded:Connect(function(child)
    if child.Name == "ErrorPrompt" then
        local GrabError = child:FindFirstChild("ErrorMessage", true)
        if GrabError then
            task.wait(0.5)
            local Reason = GrabError.Text
            if Reason:match("kick") or Reason:match("You") or Reason:match("conn") or Reason:match("rejoin") then
                game:GetService("TeleportService"):Teleport(2809202155, game:GetService("Players").LocalPlayer)
            end
        end
    end
end)

-- Ожидание загрузки
repeat task.wait() until game:IsLoaded() and game.Players.LocalPlayer and game.Players.LocalPlayer.Character

local LocalPlayer = game.Players.LocalPlayer
local Character = LocalPlayer.Character
repeat task.wait() until Character:FindFirstChild("RemoteEvent") and Character:FindFirstChild("RemoteFunction")
local RemoteFunction, RemoteEvent = Character.RemoteFunction, Character.RemoteEvent
local HRP = Character.PrimaryPart
local part
local dontTPOnDeath = true

-- Проверка уровня
if LocalPlayer.PlayerStats.Level.Value == 50 then 
    while true do 
        print("Level 50, Auto pres disabled") 
        task.wait(9999999) 
    end 
end

-- Создание HUD если нет
if not LocalPlayer.PlayerGui:FindFirstChild("HUD") then
    print("Creating HUD...")
    local HUD = game:GetService("ReplicatedStorage"):FindFirstChild("Objects")
    if HUD then
        HUD = HUD:FindFirstChild("HUD")
        if HUD then
            HUD = HUD:Clone()
            HUD.Parent = LocalPlayer.PlayerGui
        end
    end
end

print("Initializing AutoPrestige...")
RemoteEvent:FireServer("PressedPlay")

-- Удаление экранов загрузки
if LocalPlayer.PlayerGui:FindFirstChild("LoadingScreen1") then
    LocalPlayer.PlayerGui.LoadingScreen1:Destroy()
end

if LocalPlayer.PlayerGui:FindFirstChild("LoadingScreen") then
    LocalPlayer.PlayerGui.LoadingScreen:Destroy()
end

-- Удаление DepthOfField
task.spawn(function()
    if game.Lighting:WaitForChild("DepthOfField", 10) then
        game.Lighting.DepthOfField:Destroy()
    end
end)

-- БЕЗОПАСНАЯ РАБОТА С ФАЙЛАМИ (исправление для Xeno)
local Data = {}
local FileLoaded = false

-- Проверяем доступность файловых функций
local function SafeFileRead(filename)
    local success, result = pcall(function()
        if readfile then
            return readfile(filename)
        end
        return nil
    end)
    return success and result or nil
end

local function SafeFileWrite(filename, content)
    local success, result = pcall(function()
        if writefile then
            writefile(filename, content)
            return true
        end
        return false
    end)
    return success and result or false
end

local function SafeFileDelete(filename)
    local success, result = pcall(function()
        if delfile then
            delfile(filename)
            return true
        end
        return false
    end)
    return success and result or false
end

-- Загрузка данных
if LocalPlayer.PlayerStats.Level.Value ~= 50 then
    local fileContent = SafeFileRead("AutoPres3_"..LocalPlayer.Name..".txt")
    if fileContent then
        local success, decoded = pcall(function()
            return game:GetService('HttpService'):JSONDecode(fileContent)
        end)
        if success and decoded then
            Data = decoded
            FileLoaded = true
        end
    end
    
    if not FileLoaded then
        Data = {
            ["Time"] = tick(),
            ["Prestige"] = LocalPlayer.PlayerStats.Prestige.Value,
            ["Level"] = LocalPlayer.PlayerStats.Level.Value
        }
        SafeFileWrite("AutoPres3_"..LocalPlayer.Name..".txt", game:GetService('HttpService'):JSONEncode(Data))
    end
end

-- start
local lastTick = tick()

-- БЕЗОПАСНЫЕ ХУКИ (исправление для Xeno)
local function SafeHookFunction()
    local success, result = pcall(function()
        -- Проверяем доступность hookfunction
        if hookfunction then
            local itemHook
            itemHook = hookfunction(getrawmetatable(game.Players.LocalPlayer.Character.HumanoidRootPart.Position).__index, function(p,i)
                if getcallingscript() and getcallingscript().Name == "ItemSpawn" and i:lower() == "magnitude" then
                    return 0
                end
                return itemHook(p,i)
            end)
            return true
        end
        return false
    end)
    return success and result or false
end

local function SafeHookMetaMethod()
    local success, result = pcall(function()
        if hookmetamethod then
            local Hook
            Hook = hookmetamethod(game, '__namecall', function(self, ...)
                local args = {...}
                local namecallmethod = getnamecallmethod()

                if namecallmethod == "InvokeServer" then
                    if args[1] == "idklolbrah2de" then
                        return "  ___XP DE KEY"
                    end
                end

                return Hook(self, ...)
            end)
            return true
        end
        return false
    end)
    return success and result or false
end

-- Пытаемся установить хуки (не критично если не получится)
pcall(SafeHookFunction)
pcall(SafeHookMetaMethod)

--// Hop Func //--
local PlaceID = game.PlaceId
local AllIDs = {}
local foundAnything = ""
local actualHour = os.date("!*t").hour

local function TPReturner()
    local Site;
    if foundAnything == "" then
        local success, result = pcall(function()
            return game:GetService("HttpService"):JSONDecode(game:HttpGet('https://games.roblox.com/v1/games/' .. PlaceID .. '/servers/Public?sortOrder=' .. getgenv().sortOrder .. '&limit=100'))
        end)
        Site = success and result or nil
    else
        local success, result = pcall(function()
            return game:GetService("HttpService"):JSONDecode(game:HttpGet('https://games.roblox.com/v1/games/' .. PlaceID .. '/servers/Public?sortOrder=' .. getgenv().sortOrder .. '&limit=100&cursor=' .. foundAnything))
        end)
        Site = success and result or nil
    end

    if not Site or not Site.data then return end

    local ID = ""
    if Site.nextPageCursor and Site.nextPageCursor ~= "null" and Site.nextPageCursor ~= nil then
        foundAnything = Site.nextPageCursor
    end

    local num = 0;
    for _,v in pairs(Site.data) do
        local Possible = true
        ID = tostring(v.id)
        if tonumber(v.maxPlayers) > tonumber(v.playing) then
            for _,Existing in pairs(AllIDs) do
                if num ~= 0 then
                    if ID == tostring(Existing) then
                        Possible = false
                    end
                else
                    if tonumber(actualHour) ~= tonumber(Existing) then
                        pcall(function()
                            SafeFileDelete("XenonAutoPres3ServerBlocker.json")
                            AllIDs = {}
                            table.insert(AllIDs, actualHour)
                        end)
                    end
                end
                num = num + 1
            end
            if Possible == true then
                table.insert(AllIDs, ID)
                task.wait()
                pcall(function()
                    SafeFileWrite("XenonAutoPres3ServerBlocker.json", game:GetService('HttpService'):JSONEncode(AllIDs))
                    task.wait()
                    game:GetService("TeleportService"):TeleportToPlaceInstance(PlaceID, ID, game.Players.LocalPlayer)
                end)
                task.wait(4)
            end
        end
    end
end

local function Teleport()
    while task.wait() do
        pcall(function()
            if getgenv().lessPing then
                game:GetService("TeleportService"):Teleport(2809202155, game:GetService("Players").LocalPlayer)
        
                game:GetService("TeleportService").TeleportInitFailed:Connect(function()
                    game:GetService("TeleportService"):Teleport(2809202155, game:GetService("Players").LocalPlayer)
                end)
                
                repeat task.wait() until game.JobId ~= game.JobId
            end

            TPReturner()
            if foundAnything ~= "" then
                TPReturner()
            end
        end)
    end
end

-- Создание платформы
part = Instance.new("Part")
part.Parent = workspace
part.Anchored = true
part.Size = Vector3.new(25,1,25)
part.Position = Vector3.new(500, 2000, 500)
part.Transparency = 1
part.CanCollide = true

--// Obtaining Stand/Farming items //--
local function findItem(itemName)
    local ItemsDict = {
        ["Position"] = {},
        ["ProximityPrompt"] = {},
        ["Items"] = {}
    }

    local ItemSpawns = game:GetService("Workspace"):FindFirstChild("Item_Spawns")
    if not ItemSpawns then return ItemsDict end

    for _,item in pairs(ItemSpawns.Items:GetChildren()) do
        if item:FindFirstChild("MeshPart") and item:FindFirstChild("ProximityPrompt") then
            if item.ProximityPrompt.ObjectText == itemName then
                if item.ProximityPrompt.MaxActivationDistance == 8 then
                    table.insert(ItemsDict["Items"], item.ProximityPrompt.ObjectText)
                    table.insert(ItemsDict["ProximityPrompt"], item.ProximityPrompt)
                    table.insert(ItemsDict["Position"], item.MeshPart.CFrame)
                else
                    print("FAKE ITEM DETECTED")
                end
            end
        end
    end
    return ItemsDict
end

--count amount of items for checking if full of item
local function countItems(itemName)
    local itemAmount = 0

    for _,item in pairs(game.Players.LocalPlayer.Backpack:GetChildren()) do
        if item.Name == itemName then
            itemAmount += 1;
        end
    end

    print("Item count for " .. itemName .. ": " .. itemAmount)
    return itemAmount
end

--uses item, use amount to specify what worthiness
local function useItem(aItem, amount)
    task.wait()
    local item = LocalPlayer.Backpack:WaitForChild(aItem, 5)

    if not item then
        Teleport()
        return
    end

    task.wait(0.2)
    if amount then
        LocalPlayer.Character.Humanoid:EquipTool(item)
        pcall(function()
            LocalPlayer.Character:WaitForChild("RemoteFunction"):InvokeServer("LearnSkill",{["Skill"] = "Worthiness ".. amount,["SkillTreeType"] = "Character"})
        end)
        
        repeat 
            item:Activate() 
            task.wait(0.1) 
        until LocalPlayer.PlayerGui:FindFirstChild("DialogueGui") or tick() - lastTick > 5
        
        if LocalPlayer.PlayerGui:FindFirstChild("DialogueGui") then
            task.wait(0.2)
            local dialogueGui = LocalPlayer.PlayerGui.DialogueGui
            if dialogueGui and dialogueGui:FindFirstChild("Frame") then
                local frame = dialogueGui.Frame
                if frame:FindFirstChild("ClickContinue") then
                    frame.ClickContinue:FireSignal("MouseButton1Click")
                end
                task.wait(0.2)
                
                if frame:FindFirstChild("Options") then
                    local options = frame.Options
                    if options:FindFirstChild("Option1") then
                        options.Option1.TextButton:FireSignal("MouseButton1Click")
                    end
                end
            end
        end
    end
end

--main function (entrypoint) of standfarm
local function attemptStandFarm()
    -- Check if LocalPlayer and Character are valid to avoid accessing undefined properties
    if not LocalPlayer or not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        print("ERROR: LocalPlayer or Character is invalid.")
        return
    end
    
    -- Teleport the player to the designated position
    LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(500, 2010, 500)
    
    -- Check if the player has a valid stand (not "None")
    if LocalPlayer.PlayerStats and LocalPlayer.PlayerStats.Stand and LocalPlayer.PlayerStats.Stand.Value == "None" then
        print("DEBUG CHECK, USING MYSTERIOUS ARROW")
        useItem("Mysterious Arrow", "II")
        
        -- Wait until the player gets a stand (not "None")
        local timeout = tick() + 30
        repeat 
            task.wait(0.5) 
        until LocalPlayer.PlayerStats.Stand.Value ~= "None" or tick() > timeout
        
        if LocalPlayer.PlayerStats.Stand.Value ~= "None" then
            -- Check if standList exists and contains the player's stand
            if not getgenv().standList or not getgenv().standList[LocalPlayer.PlayerStats.Stand.Value] then
                print("DEBUG CHECK, USING ROKAKAKA")
                useItem("Rokakaka", "II")
            elseif getgenv().standList[LocalPlayer.PlayerStats.Stand.Value] then
                dontTPOnDeath = true
                Teleport()
            end
        end

    -- If the player already has a stand, check if it's valid
    elseif LocalPlayer.PlayerStats and LocalPlayer.PlayerStats.Stand and LocalPlayer.PlayerStats.Stand.Value ~= "None" then
        if not getgenv().standList or not getgenv().standList[LocalPlayer.PlayerStats.Stand.Value] then
            print("DEBUG CHECK, USING ROKAKAKA TO CLEAR STAND")
            useItem("Rokakaka", "II")
        end
    end
end

--teleport not to get caught
local function getitem(item, itemIndex)
    local gotItem = false
    local timeout = getgenv().waitUntilCollect + 5

    if Character:FindFirstChild("SummonedStand") then
        if Character:FindFirstChild("SummonedStand").Value then
            RemoteFunction:InvokeServer("ToggleStand", "Toggle")
        end
    end

    LocalPlayer.Backpack.ChildAdded:Connect(function()
        gotItem = true
    end)
    
    task.spawn(function()
        while not gotItem and Character and Character:FindFirstChild("HumanoidRootPart") do
            task.wait()
            if item["Position"][itemIndex] then
                Character.HumanoidRootPart.CFrame = item["Position"][itemIndex] - Vector3.new(0,10,0)
            end
        end
    end)

    task.wait(getgenv().waitUntilCollect)

    task.spawn(function()
        if item["ProximityPrompt"][itemIndex] then
            fireproximityprompt(item["ProximityPrompt"][itemIndex])
        end
        
        local screenGui = LocalPlayer.PlayerGui:WaitForChild("ScreenGui",5)
        
        if not screenGui then
            return
        end

        local screenGuiPart = screenGui:WaitForChild("Part")
        for _, button in pairs(screenGuiPart:GetDescendants()) do
            if button:FindFirstChild("Part") then
                if button:IsA("ImageButton") and button:WaitForChild("Part").TextColor3 == Color3.new(0, 1, 0) then
                    repeat
                        button:FireSignal("MouseEnter")
                        button:FireSignal("MouseButton1Up")
                        button:FireSignal("MouseButton1Click")
                        button:FireSignal("Activated")
                        task.wait(0.1)
                    until not LocalPlayer.PlayerGui:FindFirstChild("ScreenGui") or tick() - lastTick > 10
                end
            end
        end
    end)
    
    task.spawn(function()
        for i=timeout, 1, -1 do
            task.wait(1)
        end

        if not gotItem then
            gotItem = true
            return
        end
    end)

    repeat task.wait(0.1) until gotItem or tick() - lastTick > timeout
end

--farm item with said name and amount
local function farmItem(itemName, amount)
    local items = findItem(itemName)
    local currentAmount = countItems(itemName)
    
    if currentAmount >= amount then
        print("ALREADY HAVE ENOUGH " .. itemName)
        return true
    end

    for itemIndex, _ in pairs(items["Position"]) do
        if countItems(itemName) >= amount then
            print("SUCCESSFULLY COLLECTED " .. itemName)
            break
        else
            getitem(items, itemIndex)
        end
    end
    
    return countItems(itemName) >= amount
end

--// End Dialogue Func //--
local function endDialogue(NPC, Dialogue, Option)
    local dialogueToEnd = {
        ["NPC"] = NPC,
        ["Dialogue"] = Dialogue,
        ["Option"] = Option
     }
    RemoteEvent:FireServer("EndDialogue", dialogueToEnd)
end

--// End Storyline Dialogue Func //--
local function storyDialogue()
    local Quest = {
        ["Storyline"] = {"#1", "#1", "#1", "#2", "#3", "#3", "#3", "#4", "#5", "#6", "#7", "#8", "#9", "#10", "#11", "#11", "#12", "#14"},
        ["Dialogue"] = {"Dialogue2", "Dialogue6", "Dialogue6", "Dialogue3", "Dialogue3", "Dialogue3", "Dialogue6", "Dialogue3", "Dialogue5", "Dialogue5", "Dialogue5", "Dialogue4", "Dialogue7", "Dialogue6", "Dialogue8", "Dialogue11", "Dialogue3", "Dialogue2"}
    }
    
    for counter = 1, 18 do
        pcall(function()
            RemoteEvent:FireServer("EndDialogue", {
                ["NPC"] = "Storyline".. " " .. Quest["Storyline"][counter],
                ["Dialogue"] = Quest["Dialogue"][counter],
                ["Option"] = "Option1"
            })
        end)
        task.wait(0.1)
    end
end

local function killNPC(npcName, playerDistance, dontDestroyOnKill, extraParameters)
    print("ATTEMPTING TO KILL: " .. npcName)

    local NPC = workspace.Living:WaitForChild(npcName, getgenv().NPCTimeOut)
    if not NPC then
        print("NPC NOT FOUND: " .. npcName)
        Teleport()
        return false
    end

    local beingTargeted = true
    local doneKilled = false
    local deadCheck

    local function setStandMorphPosition()
        pcall(function()
            if not NPC or not NPC:FindFirstChild("HumanoidRootPart") then return end
            
            if LocalPlayer.PlayerStats.Stand.Value == "None" then
                HRP.CFrame = NPC.HumanoidRootPart.CFrame - Vector3.new(0, 5, 0)
                return
            end

            if not Character:FindFirstChild("SummonedStand") or not Character.SummonedStand.Value or not Character:FindFirstChild("StandMorph") then
                RemoteFunction:InvokeServer("ToggleStand", "Toggle")
                return
            end

            Character.StandMorph.PrimaryPart.CFrame = NPC.HumanoidRootPart.CFrame + NPC.HumanoidRootPart.CFrame.lookVector * -1.1
            HRP.CFrame = Character.StandMorph.PrimaryPart.CFrame + Character.StandMorph.PrimaryPart.CFrame.lookVector - Vector3.new(0, playerDistance, 0)
            
            if not Character:FindFirstChild("FocusCam") then
                local FocusCam = Instance.new("ObjectValue", Character)
                FocusCam.Name = "FocusCam"
                FocusCam.Value = Character.StandMorph.PrimaryPart
            end
            
            if Character:FindFirstChild("FocusCam") and Character.FocusCam.Value ~= Character.StandMorph.PrimaryPart then
                Character.FocusCam.Value = Character.StandMorph.PrimaryPart
            end
        end)
    end

    local function HamonCharge()
        if not Character:FindFirstChild("Hamon") then
            return
        end

        if Character.Hamon.Value <= getgenv().HamonCharge then
            RemoteFunction:InvokeServer("AssignSkillKey", {["Type"] = "Spec",["Key"] = "Enum.KeyCode.L",["Skill"] = "Hamon Breathing"})
            Character.RemoteEvent:FireServer("InputBegan", {["Input"] = Enum.KeyCode.L})
        end
    end

    local function BlockBreaker()
        if not NPC or NPC.Parent == nil then
            return
        end
    
        if game:GetService("CollectionService"):HasTag(NPC, "Blocking") then
            RemoteEvent:FireServer("InputBegan", {["Input"] = Enum.KeyCode.R})
        elseif NPC.Humanoid.Health <= 1 then
            task.spawn(function()
                task.wait(5)
                if NPC then
                    RemoteFunction:InvokeServer("Attack", "m1")
                end
            end)
        elseif NPC.Humanoid.Health >= 1 then
            RemoteFunction:InvokeServer("Attack", "m1")
        end
    end

    deadCheck = LocalPlayer.PlayerGui.HUD.Main.DropMoney.Money.ChildAdded:Connect(function(child)
        local number = tonumber(string.match(child.Name,"%d+"))
        if number and NPC then
            doneKilled = true
            deadCheck:Disconnect()
            if not dontDestroyOnKill then
                pcall(function() NPC:Destroy() end)
            end
        end
    end)

    local startTime = tick()
    while beingTargeted and tick() - startTime < 60 do  -- 60 секунд таймаут
        task.wait(0.1)
        if not NPC or not NPC:FindFirstChild("HumanoidRootPart") then
            if deadCheck then deadCheck:Disconnect() end
            beingTargeted = false
            break
        end
    
        if extraParameters then
            pcall(extraParameters)
        end
    
        task.spawn(setStandMorphPosition)
        task.spawn(HamonCharge)
        task.spawn(BlockBreaker)
    end
    
    if deadCheck then deadCheck:Disconnect() end
    return doneKilled
end 

local function checkPrestige(level, prestige)
    if (level == 35 and prestige == 0) or (level == 40 and prestige == 1) or (level == 45 and prestige == 2) then
        pcall(function()
            endDialogue("Prestige", "Dialogue2", "Option1")
        end)
        return true
    end
    return false
end

local function allocateSkills()
    task.spawn(function()
        pcall(function()
            RemoteFunction:InvokeServer("LearnSkill", {["Skill"] = "Destructive Power V",["SkillTreeType"] = "Stand"})
            RemoteFunction:InvokeServer("LearnSkill", {["Skill"] = "Destructive Power IV",["SkillTreeType"] = "Stand"})
            RemoteFunction:InvokeServer("LearnSkill", {["Skill"] = "Destructive Power III",["SkillTreeType"] = "Stand"})
            RemoteFunction:InvokeServer("LearnSkill", {["Skill"] = "Destructive Power II",["SkillTreeType"] = "Stand"})
            RemoteFunction:InvokeServer("LearnSkill", {["Skill"] = "Destructive Power I",["SkillTreeType"] = "Stand"})
            
            if LocalPlayer.PlayerStats.Spec.Value == "Hamon (William Zeppeli)" then
                RemoteFunction:InvokeServer("LearnSkill", {["Skill"] = "Hamon Punch V",["SkillTreeType"] = "Spec"})
                RemoteFunction:InvokeServer("LearnSkill", {["Skill"] = "Lung Capacity V", ["SkillTreeType"] = "Spec"})
                RemoteFunction:InvokeServer("LearnSkill", {["Skill"] = "Breathing Technique V",["SkillTreeType"] = "Spec"})
            end
        end)
    end)
end

-- ГЛАВНАЯ ФУНКЦИЯ С ИСПРАВЛЕННЫМИ ОШИБКАМИ
local function autoStory()
    local questPanel = LocalPlayer.PlayerGui.HUD.Main.Frames.Quest.Quests
    local repeatCount = 0
    allocateSkills()

    -- Проверка на Requiem Arrow
    if LocalPlayer.PlayerStats.Level.Value >= 25 and LocalPlayer.PlayerStats.Prestige.Value >= 1 and LocalPlayer.Backpack:FindFirstChild("Requiem Arrow") and (LocalPlayer.PlayerStats.Stand.Value == "King Crimson" or LocalPlayer.PlayerStats.Stand.Value == "Star Platinum") then
        LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(500, 2010, 500)
        local oldStand = LocalPlayer.PlayerStats.Stand.Value
        useItem("Requiem Arrow", "V")
        local timeout = tick() + 10
        repeat task.wait(0.5) until LocalPlayer.PlayerStats.Stand.Value ~= oldStand or tick() > timeout
        autoStory()
        return
    end

    -- Получение Hamon
    if LocalPlayer.PlayerStats.Spec.Value == "None" and LocalPlayer.PlayerStats.Level.Value >= 25 then
        local function collectAndSell(toolName, amount)
            if countItems(toolName) < amount then
                farmItem(toolName, amount)
            end
            local item = LocalPlayer.Backpack:FindFirstChild(toolName)
            if item then
                LocalPlayer.Character.Humanoid:EquipTool(item)
                endDialogue("Merchant", "Dialogue5", "Option2")
            end
        end
        
        if not LocalPlayer.Backpack:FindFirstChild("Zeppeli's Hat") then
            task.wait(2)
            farmItem("Zeppeli's Hat", 1)
        end

        if LocalPlayer.PlayerStats.Money.Value <= 10000 then
            print("FARMING MONEY FOR HAMON...")
            collectAndSell("Mysterious Arrow", 25)
            collectAndSell("Rokakaka", 25)
            collectAndSell("Diamond", 10)
            collectAndSell("Steel Ball", 10)
            collectAndSell("Quinton's Glove", 10)
            collectAndSell("Pure Rokakaka", 10)
            collectAndSell("Ribcage Of The Saint's Corpse", 10)
            collectAndSell("Ancient Scroll", 10)
            collectAndSell("Clackers", 10)
            collectAndSell("Caesar's headband", 10)
        end

        if LocalPlayer.Backpack:FindFirstChild("Zeppeli's Hat") then
            LocalPlayer.Character.Humanoid:EquipTool(LocalPlayer.Backpack:FindFirstChild("Zeppeli's Hat"))
            local lisaLisa = game.ReplicatedStorage.NewDialogue:FindFirstChild("Lisa Lisa")
            if lisaLisa then
                game.Players.LocalPlayer.Character.RemoteEvent:FireServer("PromptTriggered", lisaLisa)
                
                local startTime = tick()
                repeat
                    task.wait(0.1)
                until LocalPlayer.PlayerGui:FindFirstChild("DialogueGui") or tick() - startTime > 10
                
                if LocalPlayer.PlayerGui:FindFirstChild("DialogueGui") then
                    -- Автоклик по диалогам
                    for i = 1, 10 do
                        task.wait(0.5)
                        if not LocalPlayer.PlayerGui:FindFirstChild("DialogueGui") then break end
                    end
                end
            end
            task.wait(5)
            autoStory()
            return
        else
            Teleport()
            return
        end
    end
        
    -- Поиск активных квестов
    while #questPanel:GetChildren() < 2 and repeatCount < 100 do
        if not questPanel:FindFirstChild("Take down 3 vampires") then
            lastTick = tick()
            endDialogue("William Zeppeli", "Dialogue4", "Option1")
        end
    
        pcall(function()
            LocalPlayer.QuestsRemoteFunction:InvokeServer({[1] = "ReturnData"})
        end)
        storyDialogue()
        task.wait(0.5)
        repeatCount = repeatCount + 1
    end

    if repeatCount >= 100 then
        Teleport()
        return
    end

    -- Обработка квестов
    if questPanel:FindFirstChild("Help Giorno by Defeating Security Guards") then
        print('QUEST: Security Guard')
        if killNPC("Security Guard", 15) then
            task.wait(1)
            storyDialogue()
            autoStory()
        else
            autoStory()
        end
        return

    elseif not getgenv().standList[LocalPlayer.PlayerStats.Stand.Value] and LocalPlayer.PlayerStats.Level.Value >= 3 and dontTPOnDeath then
        print('NO VALID STAND - FARMING')
        task.wait(2)
        farmItem("Rokakaka", 25)
        farmItem("Mysterious Arrow", 25)
        farmItem("Zeppeli's Hat", 1)

        if countItems("Mysterious Arrow") >= 25 and countItems("Rokakaka") >= 25 then
            print("STARTING STAND FARM")
            dontTPOnDeath = false
            attemptStandFarm()
        else
            Teleport()
        end
        return

    elseif questPanel:FindFirstChild("Defeat Leaky Eye Luca") and getgenv().standList[LocalPlayer.PlayerStats.Stand.Value] then
        print("QUEST: Leaky Eye Luca")
        if killNPC("Leaky Eye Luca", 15) then
            task.wait(1)
            storyDialogue()
            autoStory()
        else
            autoStory()
        end
        return

    elseif questPanel:FindFirstChild("Defeat Bucciarati") then
        print("QUEST: Bucciarati")
        if killNPC("Bucciarati", 15) then
            task.wait(1)
            storyDialogue()
            autoStory()
        else
            autoStory()
        end
        return

    elseif questPanel:FindFirstChild("Collect $5,000 To Cover For Popo's Real Fortune") then
        print("QUEST: Need $5000")
        if LocalPlayer.PlayerStats.Money.Value < 5000 then
            local function collectAndSell(toolName, amount)
                if countItems(toolName) < amount then
                    farmItem(toolName, amount)
                end
                local item = LocalPlayer.Backpack:FindFirstChild(toolName)
                if item then
                    Character.Humanoid:EquipTool(item)
                    endDialogue("Merchant", "Dialogue5", "Option2")
                end
            end
            
            task.wait(2)
            collectAndSell("Mysterious Arrow", 25)
            collectAndSell("Rokakaka", 25)
            collectAndSell("Diamond", 10)
            collectAndSell("Steel Ball", 10)
            collectAndSell("Quinton's Glove", 10)
            collectAndSell("Pure Rokakaka", 10)
            collectAndSell("Ribcage Of The Saint's Corpse", 10)
            collectAndSell("Ancient Scroll", 10)
            collectAndSell("Clackers", 10)
            collectAndSell("Caesar's headband", 10)
        end
        autoStory()
        return

    elseif questPanel:FindFirstChild("Defeat Fugo And His Purple Haze") then
        print("QUEST: Fugo")
        if killNPC("Fugo", 15) then
            task.wait(1)
            storyDialogue()
            autoStory()
        else
            autoStory()
        end
        return

    elseif questPanel:FindFirstChild("Defeat Pesci") then
        print("QUEST: Pesci")
        if killNPC("Pesci", 15) then
            task.wait(1)
            storyDialogue()
            autoStory()
        else
            autoStory()
        end
        return

    elseif questPanel:FindFirstChild("Defeat Ghiaccio") then
        print("QUEST: Ghiaccio")
        if killNPC("Ghiaccio", 15) then
            task.wait(1)
            storyDialogue()
            autoStory()
        else
            autoStory()
        end
        return

    elseif questPanel:FindFirstChild("Defeat Diavolo") then
        print("QUEST: Diavolo")
        if killNPC("Diavolo", 15) then
            endDialogue("Storyline #14", "Dialogue7", "Option1")
            if Character:WaitForChild("Requiem Arrow", 3) then
                LocalPlayer.Character.Humanoid.Health = 0
                Teleport()
            else
                autoStory()
            end
        else
            autoStory()
        end
        return

    elseif questPanel:FindFirstChild("Take down 3 vampires") and LocalPlayer.PlayerStats.Spec.Value ~= "None" and LocalPlayer.PlayerStats.Level.Value >= 25 and LocalPlayer.PlayerStats.Level.Value ~= 50 then
        getgenv().HamonCharge = 10
        local function vampire()
            if workspace.Living:FindFirstChild("Vampire") then
                LocalPlayer.Character.PrimaryPart.CFrame = workspace.Living.Vampire.HumanoidRootPart.CFrame - Vector3.new(0, 15, 0)
            end
            if not questPanel:FindFirstChild("Take down 3 vampires") then
                if (tick() - lastTick) >= 5 then
                    lastTick = tick()
                end
                endDialogue("William Zeppeli", "Dialogue4", "Option1")
            end
        end

        killNPC("Vampire", 15, false, vampire)
        autoStory()
        return

    elseif LocalPlayer.PlayerStats.Level.Value == 50 then
        if Character:FindFirstChild("FocusCam") then
            Character.FocusCam:Destroy()
        end
        pcall(function()
            SafeFileDelete("AutoPres3_"..LocalPlayer.Name..".txt")
        end)
        print("LEVEL 50 REACHED - SCRIPT STOPPED")
        return
    end
    
    -- Если не найден подходящий квест, ждем и пробуем снова
    task.wait(5)
    autoStory()
end

-- Проверка престижа в фоне
task.spawn(function()
    while task.wait(5) do
        if checkPrestige(LocalPlayer.PlayerStats.Level.Value, LocalPlayer.PlayerStats.Prestige.Value) then
            print("PRESTIGE AVAILABLE - TELEPORTING")
            Teleport()
        elseif LocalPlayer.PlayerStats.Level.Value == 50 then
            if Character:FindFirstChild("FocusCam") then
                Character.FocusCam:Destroy()
            end
            break
        else
            -- print("Not able to prestige yet")
        end
    end
end)

-- Респавн персонажа
game.Workspace.Living.ChildAdded:Connect(function(character)
    if character.Name == LocalPlayer.Name then
        if LocalPlayer.PlayerStats.Level.Value == 50 then
            print("DIED AT LEVEL 50")
        else
            if dontTPOnDeath then
                Teleport()
            else
                attemptStandFarm()
            end
        end
    end
end)

-- NoClip обход (безопасная версия)
task.spawn(function()
    while task.wait(0.1) do
        pcall(function()
            if Character then
                for _, part in pairs(Character:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.CanCollide = false
                    end
                end
            end
        end)
    end
end)

-- ЗАПУСК СКРИПТА С GUI ИНДИКАТОРОМ
print("========================================")
print("YBA AutoPrestige Fixed для Xeno")
print("Успешно загружен и исправлен!")
print("========================================")

-- Создаем простой GUI индикатор
task.spawn(function()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Parent = game.CoreGui
    
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 200, 0, 80)
    frame.Position = UDim2.new(0, 10, 0, 10)
    frame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    frame.Parent = screenGui
    
    local title = Instance.new("TextLabel")
    title.Text = "YBA AutoPrestige"
    title.Size = UDim2.new(1, 0, 0, 30)
    title.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
    title.TextColor3 = Color3.fromRGB(0, 255, 0)
    title.Font = Enum.Font.GothamBold
    title.Parent = frame
    
    local status = Instance.new("TextLabel")
    status.Text = "Status: RUNNING"
    status.Size = UDim2.new(1, 0, 0, 50)
    status.Position = UDim2.new(0, 0, 0, 30)
    status.TextColor3 = Color3.fromRGB(255, 255, 255)
    status.BackgroundTransparency = 1
    status.Font = Enum.Font.Gotham
    status.Parent = frame
    
    -- Обновление статуса
    while task.wait(1) do
        pcall(function()
            status.Text = "Level: " .. LocalPlayer.PlayerStats.Level.Value .. 
                         "\nStand: " .. LocalPlayer.PlayerStats.Stand.Value
        end)
    end
end)

-- Запуск основной функции
task.wait(2)
autoStory()
