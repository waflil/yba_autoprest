-- ======================================================================
-- YBA Autofarm Ultimate (адаптированная версия)
-- Основано на профессиональном скрипте с GitHub
-- ======================================================================

-- === КОНФИГУРАЦИЯ ===
getgenv().Config = {
    AutoFarm = true,
    StandList = {
        ["The World"] = true,
        ["Star Platinum"] = true,
        ["Star Platinum: The World"] = true,
        ["Crazy Diamond"] = true,
        ["King Crimson"] = true,
        ["King Crimson Requiem"] = true
    },
    HamonCharge = 90,
    NPCTimeOut = 15,
    AttackRange = 15,
    FarmDelay = 0.5
}

-- === ИНИЦИАЛИЗАЦИЯ ===
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RS = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")

-- === ОСНОВНЫЕ ФУНКЦИИ ===

-- 1A: Завершение диалога
function EndDialogue(NPC, Dialogue, Option)
    local DialogueData = {
        ["NPC"] = NPC,
        ["Dialogue"] = Dialogue,
        ["Option"] = Option
    }
    Character.RemoteEvent:FireServer("EndDialogue", DialogueData)
end

-- 1B: Автодиалог для сюжета
function AutoStoryDialogue()
    local Story = {
        ["Quests"] = {"#1", "#1", "#1", "#2", "#3", "#3", "#3", "#4", "#5", "#6", "#7", "#8", "#9", "#10", "#11", "#11", "#12", "#14"},
        ["Dialogues"] = {"Dialogue2", "Dialogue6", "Dialogue6", "Dialogue3", "Dialogue3", "Dialogue3", "Dialogue6", "Dialogue3", "Dialogue5", "Dialogue5", "Dialogue5", "Dialogue4", "Dialogue7", "Dialogue6", "Dialogue8", "Dialogue11", "Dialogue3", "Dialogue2"}
    }
    
    for i = 1, 18 do
        EndDialogue("Storyline" .. " " .. Story["Quests"][i], Story["Dialogues"][i], "Option1")
        task.wait(0.1)
    end
end

-- 2A: Убийство NPC
function KillNPC(npcName, distance)
    local NPC = Workspace.Living:WaitForChild(npcName, Config.NPCTimeOut)
    if not NPC then return false end
    
    local killed = false
    
    -- Телепорт к NPC
    HumanoidRootPart.CFrame = NPC.HumanoidRootPart.CFrame * CFrame.new(0, 0, distance)
    
    -- Автоатака
    local attackLoop = task.spawn(function()
        while NPC and NPC.Humanoid.Health > 0 and Config.AutoFarm do
            task.wait()
            -- Использование стойки, если есть
            if Character:FindFirstChild("SummonedStand") and Character.SummonedStand.Value then
                Character.RemoteFunction:InvokeServer("Attack", "m1")
            else
                -- Базовая атака
                game:GetService("VirtualInputManager"):SendKeyEvent(true, Enum.KeyCode.E, false, game)
                task.wait(0.1)
                game:GetService("VirtualInputManager"):SendKeyEvent(false, Enum.KeyCode.E, false, game)
            end
        end
    end)
    
    -- Ожидание смерти
    repeat task.wait(0.5) until not NPC or NPC.Humanoid.Health <= 0
    task.cancel(attackLoop)
    
    if NPC and NPC.Humanoid.Health <= 0 then
        killed = true
        NPC:Destroy()
    end
    
    return killed
end

-- 2B: Фарм предметов
function FarmItem(itemName, amount)
    local ItemSpawns = Workspace:FindFirstChild("Item_Spawns")
    if not ItemSpawns then return end
    
    local itemsCollected = 0
    
    for _, item in pairs(ItemSpawns.Items:GetChildren()) do
        if itemsCollected >= amount then break end
        
        if item:FindFirstChild("MeshPart") and item:FindFirstChild("ProximityPrompt") then
            if item.ProximityPrompt.ObjectText == itemName then
                -- Телепорт к предмету
                HumanoidRootPart.CFrame = item.MeshPart.CFrame * CFrame.new(0, 0, 3)
                task.wait(0.3)
                
                -- Взаимодействие
                fireproximityprompt(item.ProximityPrompt)
                itemsCollected = itemsCollected + 1
                task.wait(Config.FarmDelay)
            end
        end
    end
    
    return itemsCollected
end

-- 2C: Использование предмета
function UseItem(itemName)
    local item = LocalPlayer.Backpack:FindFirstChild(itemName)
    if not item then return false end
    
    Character.Humanoid:EquipTool(item)
    task.wait(0.2)
    item:Activate()
    return true
end

-- 3A: Проверка престижа
function CheckPrestige()
    local Level = LocalPlayer.PlayerStats.Level.Value
    local Prestige = LocalPlayer.PlayerStats.Prestige.Value
    
    if (Level == 35 and Prestige == 0) or 
       (Level == 40 and Prestige == 1) or 
       (Level == 45 and Prestige == 2) then
        EndDialogue("Prestige", "Dialogue2", "Option1")
        return true
    end
    return false
end

-- 3B: Автофарм стенда
function AutoStandFarm()
    if LocalPlayer.PlayerStats.Stand.Value == "None" then
        -- Фарм стрел и рокаки
        FarmItem("Mysterious Arrow", 1)
        UseItem("Mysterious Arrow")
        
        -- Ожидание стенда
        repeat task.wait(1) until LocalPlayer.PlayerStats.Stand.Value ~= "None"
        
        -- Если не нужный стенд - использовать рокаку
        if not Config.StandList[LocalPlayer.PlayerStats.Stand.Value] then
            FarmItem("Rokakaka", 1)
            UseItem("Rokakaka")
        end
    end
end

-- 3C: Основной цикл сюжета
function MainStoryLoop()
    while Config.AutoFarm do
        task.wait(1)
        
        -- Проверка интерфейса квестов
        local QuestPanel = LocalPlayer.PlayerGui.HUD.Main.Frames.Quest.Quests
        
        -- Автодиалог
        AutoStoryDialogue()
        
        -- Определение текущего квеста
        if QuestPanel:FindFirstChild("Help Giorno by Defeating Security Guards") then
            print("[AUTO] Квест: Security Guards")
            if KillNPC("Security Guard", Config.AttackRange) then
                task.wait(2)
                AutoStoryDialogue()
            end
            
        elseif QuestPanel:FindFirstChild("Defeat Leaky Eye Luca") then
            print("[AUTO] Квест: Leaky Eye Luca")
            if KillNPC("Leaky Eye Luca", Config.AttackRange) then
                task.wait(2)
                AutoStoryDialogue()
            end
            
        elseif QuestPanel:FindFirstChild("Defeat Bucciarati") then
            print("[AUTO] Квест: Bucciarati")
            if KillNPC("Bucciarati", Config.AttackRange) then
                task.wait(2)
                AutoStoryDialogue()
            end
            
        elseif QuestPanel:FindFirstChild("Defeat Fugo And His Purple Haze") then
            print("[AUTO] Квест: Fugo")
            if KillNPC("Fugo", Config.AttackRange) then
                task.wait(2)
                AutoStoryDialogue()
            end
            
        elseif QuestPanel:FindFirstChild("Take down 3 vampires") then
            print("[AUTO] Квест: Vampires")
            for i = 1, 3 do
                if KillNPC("Vampire", Config.AttackRange) then
                    task.wait(2)
                end
            end
            AutoStoryDialogue()
            
        elseif QuestPanel:FindFirstChild("Collect $5,000 To Cover For Popo's Real Fortune") then
            print("[AUTO] Квест: Фарм денег")
            -- Фарм и продажа предметов
            local itemsToFarm = {
                "Mysterious Arrow",
                "Rokakaka", 
                "Diamond",
                "Steel Ball"
            }
            
            for _, item in pairs(itemsToFarm) do
                if LocalPlayer.PlayerStats.Money.Value < 5000 then
                    FarmItem(item, 5)
                    UseItem(item)
                    -- Продажа через торговца
                    EndDialogue("Merchant", "Dialogue5", "Option2")
                end
            end
            
        -- Проверка стенда
        elseif not Config.StandList[LocalPlayer.PlayerStats.Stand.Value] then
            print("[AUTO] Фарм нужного стенда")
            AutoStandFarm()
            
        -- Проверка престижа
        elseif CheckPrestige() then
            print("[AUTO] Престиж доступен!")
            task.wait(5)
            
        else
            -- Если квестов нет - берем новый
            EndDialogue("William Zeppeli", "Dialogue4", "Option1")
            task.wait(2)
        end
    end
end

-- === GUI ===
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Parent = game.CoreGui

local Frame = Instance.new("Frame")
Frame.Size = UDim2.new(0, 250, 0, 200)
Frame.Position = UDim2.new(0, 20, 0, 20)
Frame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
Frame.Parent = ScreenGui

local Title = Instance.new("TextLabel")
Title.Text = "YBA AUTOFARM ULTIMATE"
Title.Size = UDim2.new(1, 0, 0, 40)
Title.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.Parent = Frame

local Status = Instance.new("TextLabel")
Status.Text = "СТАТУС: АКТИВЕН"
Status.Size = UDim2.new(1, 0, 0, 30)
Status.Position = UDim2.new(0, 0, 0, 50)
Status.BackgroundColor3 = Color3.fromRGB(0, 100, 0)
Status.TextColor3 = Color3.fromRGB(255, 255, 255)
Status.Parent = Frame

local ToggleBtn = Instance.new("TextButton")
ToggleBtn.Text = "ПАУЗА"
ToggleBtn.Size = UDim2.new(0.8, 0, 0, 40)
ToggleBtn.Position = UDim2.new(0.1, 0, 0, 100)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleBtn.Parent = Frame

local InfoLabel = Instance.new("TextLabel")
InfoLabel.Text = "F5: Вкл/Выкл | DEL: Выход"
InfoLabel.Size = UDim2.new(1, 0, 0, 25)
InfoLabel.Position = UDim2.new(0, 0, 0, 160)
InfoLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
InfoLabel.BackgroundTransparency = 1
InfoLabel.Parent = Frame

-- === УПРАВЛЕНИЕ ===
ToggleBtn.MouseButton1Click:Connect(function()
    Config.AutoFarm = not Config.AutoFarm
    if Config.AutoFarm then
        ToggleBtn.Text = "ПАУЗА"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
        Status.Text = "СТАТУС: АКТИВЕН"
        Status.BackgroundColor3 = Color3.fromRGB(0, 100, 0)
        print("[AUTO] Возобновлено")
        MainStoryLoop()
    else
        ToggleBtn.Text = "ПРОДОЛЖИТЬ"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(50, 200, 50)
        Status.Text = "СТАТУС: ПАУЗА"
        Status.BackgroundColor3 = Color3.fromRGB(100, 0, 0)
        print("[AUTO] Приостановлено")
    end
end)

game:GetService("UserInputService").InputBegan:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.F5 then
        Config.AutoFarm = not Config.AutoFarm
        ToggleBtn.Text = Config.AutoFarm and "ПАУЗА" or "ПРОДОЛЖИТЬ"
        ToggleBtn.BackgroundColor3 = Config.AutoFarm and Color3.fromRGB(200, 50, 50) or Color3.fromRGB(50, 200, 50)
    elseif input.KeyCode == Enum.KeyCode.Delete then
        Config.AutoFarm = false
        ScreenGui:Destroy()
        print("[AUTO] Скрипт остановлен")
    end
end)

-- === ЗАЩИТА ОТ AFK ===
task.spawn(function()
    while Config.AutoFarm do
        task.wait(30)
        game:GetService("VirtualInputManager"):SendKeyEvent(true, Enum.KeyCode.W, false, game)
        task.wait(0.1)
        game:GetService("VirtualInputManager"):SendKeyEvent(false, Enum.KeyCode.W, false, game)
    end
end)

-- === ЗАПУСК ===
print("========================================")
print("YBA Autofarm Ultimate загружен!")
print("Основано на профессиональном скрипте")
print("Управление через GUI или F5/DEL")
print("========================================")

-- Запуск основного цикла
task.spawn(MainStoryLoop)
