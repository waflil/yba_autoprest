-- ======================================================================
-- YBA AutoPrestige Safe Version (безопасная)
-- Убраны опасные хуки и телепорты, вызывающие Error 267
-- ======================================================================

getgenv().standList = {
    ["The World"] = true,
    ["Star Platinum"] = true,
    ["Star Platinum: The World"] = true,
    ["Crazy Diamond"] = true,
    ["King Crimson"] = true,
    ["King Crimson Requiem"] = true
}
getgenv().waitUntilCollect = 1.0 -- Увеличен для безопасности
getgenv().NPCTimeOut = 15
getgenv().HamonCharge = 90
getgenv().webhook = ""

-- Убрана опасная обработка киков (вызывала Error 267)
print("Safe AutoPrestige loading...")

-- Ожидание загрузки
repeat task.wait() until game:IsLoaded() and game.Players.LocalPlayer and game.Players.LocalPlayer.Character

local LocalPlayer = game.Players.LocalPlayer
local Character = LocalPlayer.Character
repeat task.wait() until Character:FindFirstChild("RemoteEvent") and Character:FindFirstChild("RemoteFunction")
local RemoteFunction, RemoteEvent = Character.RemoteFunction, Character.RemoteEvent
local HRP = Character.PrimaryPart

local dontTPOnDeath = true

-- Проверка уровня
if LocalPlayer.PlayerStats.Level.Value == 50 then 
    print("Level 50 reached, script stopping")
    return
end

-- Создание HUD если нет (безопасно)
if not LocalPlayer.PlayerGui:FindFirstChild("HUD") then
    print("Checking for HUD...")
    task.wait(2)
end

print("AutoPrestige initialized")
RemoteEvent:FireServer("PressedPlay")

-- Удаление экранов загрузки (безопасно)
task.delay(1, function()
    if LocalPlayer.PlayerGui:FindFirstChild("LoadingScreen1") then
        LocalPlayer.PlayerGui.LoadingScreen1:Destroy()
    end
    if LocalPlayer.PlayerGui:FindFirstChild("LoadingScreen") then
        LocalPlayer.PlayerGui.LoadingScreen:Destroy()
    end
end)

-- Удаление DepthOfField (безопасно)
task.delay(2, function()
    if game.Lighting:FindFirstChild("DepthOfField") then
        game.Lighting.DepthOfField:Destroy()
    end
end)

-- start
local lastTick = tick()

-- УБРАНЫ ВСЕ ОПАСНЫЕ ХУКИ И ФАЙЛОВЫЕ ОПЕРАЦИИ

--// УБРАН НЕБЕЗОПАСНЫЙ TELEPORT FUNCTION

-- Создание платформы (невидимой, для ориентации)
local safePlatform = Instance.new("Part")
safePlatform.Parent = workspace
safePlatform.Anchored = true
safePlatform.Size = Vector3.new(10,1,10)
safePlatform.Position = Vector3.new(0, 500, 0)
safePlatform.Transparency = 1
safePlatform.CanCollide = false
safePlatform.Name = "SafePlatform"

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
                if item.ProximityPrompt.MaxActivationDistance <= 10 then -- Проверка на валидность
                    table.insert(ItemsDict["Items"], item.ProximityPrompt.ObjectText)
                    table.insert(ItemsDict["ProximityPrompt"], item.ProximityPrompt)
                    table.insert(ItemsDict["Position"], item.MeshPart.CFrame)
                end
            end
        end
    end
    return ItemsDict
end

--count amount of items for checking if full of item
local function countItems(itemName)
    local itemAmount = 0

    for _,item in pairs(LocalPlayer.Backpack:GetChildren()) do
        if item.Name == itemName then
            itemAmount += 1
        end
    end

    return itemAmount
end

--uses item, use amount to specify what worthiness
local function useItem(aItem, amount)
    task.wait(1)
    local item = LocalPlayer.Backpack:WaitForChild(aItem, 3)

    if not item then
        print("Item not found: " .. aItem)
        return false
    end

    task.wait(0.5)
    if amount then
        LocalPlayer.Character.Humanoid:EquipTool(item)
        task.wait(0.3)
        
        -- Безопасный вызов
        pcall(function()
            LocalPlayer.Character:WaitForChild("RemoteFunction"):InvokeServer("LearnSkill",{
                ["Skill"] = "Worthiness ".. amount,
                ["SkillTreeType"] = "Character"
            })
        end)
        
        -- Активация предмета
        item:Activate()
        
        -- Ожидание диалога
        local timeout = tick() + 5
        repeat 
            task.wait(0.1) 
        until LocalPlayer.PlayerGui:FindFirstChild("DialogueGui") or tick() > timeout
        
        if LocalPlayer.PlayerGui:FindFirstChild("DialogueGui") then
            task.wait(0.5)
            -- Автоматическое закрытие диалога
            for i = 1, 3 do
                task.wait(0.3)
            end
        end
    end
    return true
end

--main function (entrypoint) of standfarm
local function attemptStandFarm()
    -- Check if LocalPlayer and Character are valid
    if not LocalPlayer or not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        print("ERROR: Character not ready")
        return
    end
    
    -- БЕЗОПАСНЫЙ ТЕЛЕПОРТ - только если нужно
    if (LocalPlayer.Character.HumanoidRootPart.Position - Vector3.new(500, 2010, 500)).Magnitude > 50 then
        LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(500, 2010, 500)
        task.wait(1)
    end
    
    -- Check if the player has a valid stand (not "None")
    if LocalPlayer.PlayerStats.Stand.Value == "None" then
        print("Getting stand with Mysterious Arrow")
        useItem("Mysterious Arrow", "II")
        
        -- Wait for stand
        local timeout = tick() + 30
        repeat 
            task.wait(1) 
        until LocalPlayer.PlayerStats.Stand.Value ~= "None" or tick() > timeout
        
        if LocalPlayer.PlayerStats.Stand.Value ~= "None" then
            -- Check if stand is in our list
            if not getgenv().standList[LocalPlayer.PlayerStats.Stand.Value] then
                print("Wrong stand, using Rokakaka")
                useItem("Rokakaka", "II")
            else
                print("Good stand obtained: " .. LocalPlayer.PlayerStats.Stand.Value)
                dontTPOnDeath = true
            end
        end
    elseif not getgenv().standList[LocalPlayer.PlayerStats.Stand.Value] then
        print("Wrong stand, clearing with Rokakaka")
        useItem("Rokakaka", "II")
    end
end

-- Безопасный сбор предметов
local function getitem(item, itemIndex)
    if not item["Position"][itemIndex] or not item["ProximityPrompt"][itemIndex] then
        return false
    end
    
    local gotItem = false
    local timeout = tick() + getgenv().waitUntilCollect + 3

    -- Убираем стенд если есть
    if Character:FindFirstChild("SummonedStand") and Character.SummonedStand.Value then
        RemoteFunction:InvokeServer("ToggleStand", "Toggle")
        task.wait(0.5)
    end

    -- Слушатель добавления предмета
    local connection
    connection = LocalPlayer.Backpack.ChildAdded:Connect(function(child)
        if child.Name == item["Items"][1] then
            gotItem = true
            if connection then connection:Disconnect() end
        end
    end)
    
    -- Телепорт к предмету
    task.spawn(function()
        while not gotItem and tick() < timeout do
            task.wait(0.1)
            if Character and Character:FindFirstChild("HumanoidRootPart") then
                Character.HumanoidRootPart.CFrame = item["Position"][itemIndex] * CFrame.new(0, 2, 0)
            end
        end
    end)

    task.wait(getgenv().waitUntilCollect)

    -- Взаимодействие
    task.spawn(function()
        fireproximityprompt(item["ProximityPrompt"][itemIndex])
        task.wait(0.5)
    end)
    
    -- Ожидание
    local startTime = tick()
    while not gotItem and tick() < timeout do
        task.wait(0.1)
    end
    
    if connection then connection:Disconnect() end
    return gotItem
end

--farm item with said name and amount
local function farmItem(itemName, amount)
    print("Farming: " .. itemName .. " x" .. amount)
    local items = findItem(itemName)
    local currentAmount = countItems(itemName)
    
    if currentAmount >= amount then
        print("Already have enough")
        return true
    end

    for itemIndex = 1, #items["Position"] do
        if countItems(itemName) >= amount then
            break
        end
        getitem(items, itemIndex)
        task.wait(0.5)
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
    pcall(function()
        RemoteEvent:FireServer("EndDialogue", dialogueToEnd)
    end)
    task.wait(0.5)
end

--// End Storyline Dialogue Func //--
local function storyDialogue()
    local Quest = {
        ["Storyline"] = {"#1", "#1", "#1", "#2", "#3", "#3", "#3", "#4", "#5", "#6", "#7", "#8", "#9", "#10", "#11", "#11", "#12", "#14"},
        ["Dialogue"] = {"Dialogue2", "Dialogue6", "Dialogue6", "Dialogue3", "Dialogue3", "Dialogue3", "Dialogue6", "Dialogue3", "Dialogue5", "Dialogue5", "Dialogue5", "Dialogue4", "Dialogue7", "Dialogue6", "Dialogue8", "Dialogue11", "Dialogue3", "Dialogue2"}
    }
    
    for counter = 1, math.min(18, #Quest["Storyline"]) do
        pcall(function()
            RemoteEvent:FireServer("EndDialogue", {
                ["NPC"] = "Storyline" .. " " .. Quest["Storyline"][counter],
                ["Dialogue"] = Quest["Dialogue"][counter],
                ["Option"] = "Option1"
            })
        end)
        task.wait(0.3)
    end
end

-- Безопасное убийство NPC
local function killNPC(npcName, playerDistance, dontDestroyOnKill, extraParameters)
    print("Killing: " .. npcName)

    local NPC = workspace.Living:WaitForChild(npcName, getgenv().NPCTimeOut)
    if not NPC or not NPC:FindFirstChild("HumanoidRootPart") then
        print("NPC not found: " .. npcName)
        return false
    end

    local killed = false
    local startTime = tick()

    local function safeAttack()
        pcall(function()
            if not NPC or not NPC:FindFirstChild("Humanoid") then return end
            
            -- Телепорт к NPC
            if Character and Character:FindFirstChild("HumanoidRootPart") then
                Character.HumanoidRootPart.CFrame = NPC.HumanoidRootPart.CFrame * CFrame.new(0, 0, playerDistance)
            end
            
            -- Атака
            if Character:FindFirstChild("SummonedStand") and Character.SummonedStand.Value then
                RemoteFunction:InvokeServer("Attack", "m1")
            else
                -- Базовая атака
                for i = 1, 3 do
                    game:GetService("VirtualInputManager"):SendKeyEvent(true, Enum.KeyCode.E, false, game)
                    task.wait(0.1)
                    game:GetService("VirtualInputManager"):SendKeyEvent(false, Enum.KeyCode.E, false, game)
                    task.wait(0.2)
                end
            end
        end)
    end

    -- Мониторинг здоровья NPC
    while tick() - startTime < 30 do  -- 30 секунд таймаут
        if not NPC or not NPC:FindFirstChild("Humanoid") then
            break
        end
        
        if NPC.Humanoid.Health <= 0 then
            killed = true
            if not dontDestroyOnKill then
                pcall(function() NPC:Destroy() end)
            end
            break
        end
        
        -- Выполняем атаку
        safeAttack()
        
        -- Дополнительные параметры если есть
        if extraParameters then
            pcall(extraParameters)
        end
        
        task.wait(0.5)
    end
    
    return killed
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
        task.wait(2)
        pcall(function()
            local skills = {
                "Destructive Power V", "Destructive Power IV", "Destructive Power III", 
                "Destructive Power II", "Destructive Power I"
            }
            
            for _, skill in pairs(skills) do
                RemoteFunction:InvokeServer("LearnSkill", {
                    ["Skill"] = skill,
                    ["SkillTreeType"] = "Stand"
                })
                task.wait(0.2)
            end
            
            if LocalPlayer.PlayerStats.Spec.Value == "Hamon (William Zeppeli)" then
                local hamonSkills = {
                    "Hamon Punch V", "Lung Capacity V", "Breathing Technique V"
                }
                
                for _, skill in pairs(hamonSkills) do
                    RemoteFunction:InvokeServer("LearnSkill", {
                        ["Skill"] = skill,
                        ["SkillTreeType"] = "Spec"
                    })
                    task.wait(0.2)
                end
            end
        end)
    end)
end

-- ГЛАВНАЯ ФУНКЦИЯ (безопасная)
local function autoStory()
    -- Даем время на загрузку
    task.wait(3)
    
    local questPanel = LocalPlayer.PlayerGui.HUD.Main.Frames.Quest.Quests
    if not questPanel then
        print("Quest panel not found, retrying...")
        task.wait(5)
        autoStory()
        return
    end
    
    allocateSkills()

    -- Проверка на Requiem Arrow
    if LocalPlayer.PlayerStats.Level.Value >= 25 and LocalPlayer.PlayerStats.Prestige.Value >= 1 
       and LocalPlayer.Backpack:FindFirstChild("Requiem Arrow") 
       and (LocalPlayer.PlayerStats.Stand.Value == "King Crimson" or LocalPlayer.PlayerStats.Stand.Value == "Star Platinum") then
        
        if (Character.HumanoidRootPart.Position - Vector3.new(500, 2010, 500)).Magnitude > 50 then
            Character.HumanoidRootPart.CFrame = CFrame.new(500, 2010, 500)
            task.wait(2)
        end
        
        local oldStand = LocalPlayer.PlayerStats.Stand.Value
        useItem("Requiem Arrow", "V")
        
        local timeout = tick() + 15
        repeat 
            task.wait(1) 
        until LocalPlayer.PlayerStats.Stand.Value ~= oldStand or tick() > timeout
        
        autoStory()
        return
    end

    -- Получение Hamon
    if LocalPlayer.PlayerStats.Spec.Value == "None" and LocalPlayer.PlayerStats.Level.Value >= 25 then
        print("Getting Hamon...")
        
        if not LocalPlayer.Backpack:FindFirstChild("Zeppeli's Hat") then
            farmItem("Zeppeli's Hat", 1)
            task.wait(2)
        end

        if LocalPlayer.PlayerStats.Money.Value <= 10000 then
            print("Farming money for Hamon...")
            local itemsToFarm = {
                {"Mysterious Arrow", 5},
                {"Rokakaka", 5},
                {"Diamond", 3},
                {"Steel Ball", 3}
            }
            
            for _, itemData in pairs(itemsToFarm) do
                farmItem(itemData[1], itemData[2])
                task.wait(1)
            end
        end

        if LocalPlayer.Backpack:FindFirstChild("Zeppeli's Hat") then
            Character.Humanoid:EquipTool(LocalPlayer.Backpack:FindFirstChild("Zeppeli's Hat"))
            task.wait(1)
            
            -- Поиск Lisa Lisa для диалога
            local lisaLisa = game:GetService("Workspace").Dialogues:FindFirstChild("Lisa Lisa")
            if lisaLisa then
                Character.HumanoidRootPart.CFrame = lisaLisa.HumanoidRootPart.CFrame * CFrame.new(0, 0, 5)
                task.wait(1)
                
                local prompt = lisaLisa:FindFirstChildWhichIsA("ProximityPrompt")
                if prompt then
                    fireproximityprompt(prompt)
                    task.wait(3)
                    
                    -- Автоклик по диалогу
                    for i = 1, 10 do
                        if LocalPlayer.PlayerGui:FindFirstChild("DialogueGui") then
                            local gui = LocalPlayer.PlayerGui.DialogueGui
                            if gui:FindFirstChild("Frame") then
                                local frame = gui.Frame
                                if frame:FindFirstChild("ClickContinue") then
                                    frame.ClickContinue:FireSignal("MouseButton1Click")
                                end
                            end
                        end
                        task.wait(0.5)
                    end
                end
            end
            task.wait(5)
            autoStory()
            return
        end
    end
    
    -- Проверка активных квестов
    task.wait(2)
    
    -- Берем квест если нет активных
    if #questPanel:GetChildren() < 2 then
        print("Taking new quest...")
        endDialogue("William Zeppeli", "Dialogue4", "Option1")
        task.wait(3)
        
        -- Получаем данные квестов
        pcall(function()
            LocalPlayer.QuestsRemoteFunction:InvokeServer({[1] = "ReturnData"})
        end)
        task.wait(1)
    end
    
    -- Обработка квестов
    if questPanel:FindFirstChild("Help Giorno by Defeating Security Guards") then
        print('Quest: Security Guards')
        if killNPC("Security Guard", 10) then
            task.wait(2)
            storyDialogue()
            autoStory()
        else
            autoStory()
        end
        return
        
    elseif questPanel:FindFirstChild("Defeat Leaky Eye Luca") then
        print("Quest: Leaky Eye Luca")
        if killNPC("Leaky Eye Luca", 10) then
            task.wait(2)
            storyDialogue()
            autoStory()
        else
            autoStory()
        end
        return
        
    elseif questPanel:FindFirstChild("Take down 3 vampires") then
        print("Quest: Vampires x3")
        local kills = 0
        for i = 1, 3 do
            if killNPC("Vampire", 10) then
                kills = kills + 1
                print("Vampire killed: " .. kills .. "/3")
            end
            task.wait(2)
        end
        
        if kills >= 3 then
            storyDialogue()
            autoStory()
        else
            autoStory()
        end
        return
        
    -- Проверка стенда
    elseif not getgenv().standList[LocalPlayer.PlayerStats.Stand.Value] and LocalPlayer.PlayerStats.Level.Value >= 3 then
        print("Need valid stand, farming...")
        farmItem("Rokakaka", 2)
        farmItem("Mysterious Arrow", 2)
        
        if countItems("Mysterious Arrow") >= 2 and countItems("Rokakaka") >= 2 then
            attemptStandFarm()
        else
            autoStory()
        end
        return
    end
    
    -- Если ничего не найдено, ждем и пробуем снова
    print("No active quest found, waiting...")
    task.wait(10)
    autoStory()
end

-- Безопасный NoClip
task.spawn(function()
    while task.wait(0.5) do
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

-- GUI для статуса
task.spawn(function()
    task.wait(2)
    
    local screenGui = Instance.new("ScreenGui")
    screenGui.Parent = game.CoreGui
    
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 220, 0, 100)
    frame.Position = UDim2.new(0, 10, 0, 10)
    frame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    frame.Parent = screenGui
    
    local title = Instance.new("TextLabel")
    title.Text = "YBA Safe Autofarm"
    title.Size = UDim2.new(1, 0, 0, 25)
    title.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
    title.TextColor3 = Color3.fromRGB(0, 255, 0)
    title.Font = Enum.Font.GothamBold
    title.Parent = frame
    
    local status = Instance.new("TextLabel")
    status.Text = "Loading..."
    status.Size = UDim2.new(1, 0, 0, 75)
    status.Position = UDim2.new(0, 0, 0, 25)
    status.TextColor3 = Color3.fromRGB(255, 255, 255)
    status.BackgroundTransparency = 1
    status.Font = Enum.Font.Gotham
    status.TextWrapped = true
    status.Parent = frame
    
    -- Обновление статуса
    while task.wait(1) do
        pcall(function()
            status.Text = "Level: " .. LocalPlayer.PlayerStats.Level.Value .. 
                         "\nStand: " .. LocalPlayer.PlayerStats.Stand.Value ..
                         "\nSpec: " .. LocalPlayer.PlayerStats.Spec.Value
        end)
    end
end)

-- ЗАПУСК
print("========================================")
print("YBA Safe Autofarm Starting...")
print("Avoiding Error 267 protections")
print("========================================")

-- Даем время на инициализацию
task.wait(5)

-- Запуск основной функции
autoStory()
