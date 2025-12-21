-- ======================================================================
-- YBA Autofarm Ultimate v2.0 (Исправленная версия)
-- С фиксами телепортации и расширенным GUI
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
    NPCTimeOut = 20,
    AttackRange = 10,
    FarmDelay = 1,
    WaitForDialogue = 3, -- Ожидание диалога
    CombatCheckInterval = 0.5
}

-- === ИНИЦИАЛИЗАЦИЯ ===
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RS = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")

-- === ГЛОБАЛЬНЫЕ ПЕРЕМЕННЫЕ ===
getgenv().CurrentTarget = nil
getgenv().CurrentQuest = "Ожидание квеста..."
getgenv().QuestProgress = "0%"
getgenv().KillCount = 0
getgenv().TotalKills = 0

-- === УЛУЧШЕННЫЕ ФУНКЦИИ ===

-- 1A: Умный телепорт с ожиданием
function SmartTeleport(targetCFrame, waitTime)
    if not targetCFrame then return false end
    
    HumanoidRootPart.CFrame = targetCFrame
    task.wait(waitTime or 1)
    return true
end

-- 1B: Ожидание диалога
function WaitForDialogue()
    local startTime = tick()
    while tick() - startTime < Config.WaitForDialogue do
        if LocalPlayer.PlayerGui:FindFirstChild("DialogueGui") then
            return true
        end
        task.wait(0.1)
    end
    return false
end

-- 2A: Завершение диалога с ожиданием
function EndDialogueWithWait(NPC, Dialogue, Option)
    local DialogueData = {
        ["NPC"] = NPC,
        ["Dialogue"] = Dialogue,
        ["Option"] = Option
    }
    
    -- Отправляем запрос
    Character.RemoteEvent:FireServer("EndDialogue", DialogueData)
    
    -- Ждем подтверждения
    task.wait(1)
    
    -- Проверяем, открылся ли диалог
    if WaitForDialogue() then
        -- Автоклик по диалогу
        for i = 1, 5 do
            if LocalPlayer.PlayerGui:FindFirstChild("DialogueGui") then
                local gui = LocalPlayer.PlayerGui.DialogueGui
                if gui:FindFirstChild("Frame") then
                    local frame = gui.Frame
                    if frame:FindFirstChild("ClickContinue") then
                        firesignal(frame.ClickContinue.MouseButton1Click)
                    end
                end
            end
            task.wait(0.5)
        end
        return true
    end
    return false
end

-- 2B: Автодиалог для сюжета
function AutoStoryDialogue()
    local Story = {
        ["Quests"] = {"#1", "#1", "#1", "#2", "#3", "#3", "#3", "#4", "#5", "#6", "#7", "#8", "#9", "#10", "#11", "#11", "#12", "#14"},
        ["Dialogues"] = {"Dialogue2", "Dialogue6", "Dialogue6", "Dialogue3", "Dialogue3", "Dialogue3", "Dialogue6", "Dialogue3", "Dialogue5", "Dialogue5", "Dialogue5", "Dialogue4", "Dialogue7", "Dialogue6", "Dialogue8", "Dialogue11", "Dialogue3", "Dialogue2"}
    }
    
    for i = 1, 18 do
        EndDialogueWithWait("Storyline" .. " " .. Story["Quests"][i], Story["Dialogues"][i], "Option1")
        task.wait(0.3)
    end
end

-- 3A: Поиск NPC в диалогах
function FindDialogueNPC(npcName)
    local DialoguesFolder = Workspace:FindFirstChild("Dialogues")
    if not DialoguesFolder then return nil end
    
    for _, npc in pairs(DialoguesFolder:GetChildren()) do
        if npc.Name == npcName then
            return npc
        end
    end
    
    -- Если не нашли в диалогах, ищем в Living
    return Workspace.Living:FindFirstChild(npcName)
end

-- 3B: Взятие квеста у NPC
function AcceptQuestFromNPC(npcName)
    local npc = FindDialogueNPC(npcName)
    if not npc then
        UpdateStatus("NPC не найден: " .. npcName)
        return false
    end
    
    UpdateStatus("Нахожу NPC: " .. npcName)
    
    -- Телепортируемся и остаемся рядом
    SmartTeleport(npc.HumanoidRootPart.CFrame * CFrame.new(0, 0, 5), 2)
    
    -- Взаимодействие
    local prompt = npc:FindFirstChildWhichIsA("ProximityPrompt")
    if prompt then
        fireproximityprompt(prompt)
        UpdateStatus("Взаимодействие с " .. npcName)
        task.wait(2)
        return true
    end
    
    return false
end

-- 4A: Убийство NPC с постоянным телепортом
function KillNPCContinuously(npcName, requiredKills)
    UpdateStatus("Охочусь на: " .. npcName)
    getgenv().CurrentTarget = npcName
    getgenv().KillCount = 0
    getgenv().TotalKills = requiredKills or 1
    
    local kills = 0
    local maxAttempts = requiredKills * 3
    
    for attempt = 1, maxAttempts do
        if kills >= requiredKills then break end
        if not Config.AutoFarm then break end
        
        local npc = Workspace.Living:FindFirstChild(npcName)
        if not npc then
            UpdateStatus("Ожидание появления " .. npcName)
            task.wait(3)
            npc = Workspace.Living:WaitForChild(npcName, 5)
        end
        
        if npc and npc:FindFirstChild("Humanoid") then
            -- Телепорт и удержание позиции
            HumanoidRootPart.CFrame = npc.HumanoidRootPart.CFrame * CFrame.new(0, 0, Config.AttackRange)
            
            -- Атака до смерти
            local startHealth = npc.Humanoid.Health
            local attackTime = 0
            
            while npc and npc.Humanoid.Health > 0 and Config.AutoFarm do
                -- Держим позицию
                if HumanoidRootPart then
                    HumanoidRootPart.CFrame = npc.HumanoidRootPart.CFrame * CFrame.new(0, 0, Config.AttackRange)
                end
                
                -- Атака
                if Character:FindFirstChild("SummonedStand") and Character.SummonedStand.Value then
                    Character.RemoteFunction:InvokeServer("Attack", "m1")
                else
                    game:GetService("VirtualInputManager"):SendKeyEvent(true, Enum.KeyCode.E, false, game)
                    task.wait(0.1)
                    game:GetService("VirtualInputManager"):SendKeyEvent(false, Enum.KeyCode.E, false, game)
                end
                
                -- Прогресс
                attackTime = attackTime + Config.CombatCheckInterval
                local damageDealt = startHealth - npc.Humanoid.Health
                UpdateProgress(kills + (damageDealt / startHealth), requiredKills)
                
                task.wait(Config.CombatCheckInterval)
            end
            
            if npc and npc.Humanoid.Health <= 0 then
                kills = kills + 1
                getgenv().KillCount = kills
                UpdateStatus("Убито " .. kills .. "/" .. requiredKills .. " " .. npcName)
                npc:Destroy()
                task.wait(1)
            end
        end
    end
    
    getgenv().CurrentTarget = nil
    return kills >= requiredKills
end

-- 4B: Фарм предметов с прогрессом
function FarmItemWithProgress(itemName, amount)
    UpdateStatus("Фарм предмета: " .. itemName)
    
    local ItemSpawns = Workspace:FindFirstChild("Item_Spawns")
    if not ItemSpawns then return 0 end
    
    local collected = 0
    local items = {}
    
    -- Собираем все предметы
    for _, item in pairs(ItemSpawns.Items:GetChildren()) do
        if item:FindFirstChild("MeshPart") and item:FindFirstChild("ProximityPrompt") then
            if item.ProximityPrompt.ObjectText == itemName then
                table.insert(items, item)
            end
        end
    end
    
    for _, item in pairs(items) do
        if collected >= amount then break end
        if not Config.AutoFarm then break end
        
        -- Телепорт и удержание позиции
        SmartTeleport(item.MeshPart.CFrame * CFrame.new(0, 0, 3), 1)
        
        -- Взаимодействие
        fireproximityprompt(item.ProximityPrompt)
        collected = collected + 1
        
        -- Прогресс
        UpdateProgress(collected, amount)
        UpdateStatus("Собрано " .. collected .. "/" .. amount .. " " .. itemName)
        
        task.wait(Config.FarmDelay)
    end
    
    return collected
end

-- 5A: Обновление статуса в GUI
function UpdateStatus(message)
    getgenv().CurrentQuest = message
    if StatusLabel then
        StatusLabel.Text = "Статус: " .. message
    end
    print("[AUTO] " .. message)
end

-- 5B: Обновление прогресса
function UpdateProgress(current, total)
    if total > 0 then
        local percent = math.floor((current / total) * 100)
        getgenv().QuestProgress = percent .. "%"
        if ProgressBar then
            ProgressBar.Size = UDim2.new(percent / 100, 0, 1, 0)
        end
        if ProgressText then
            ProgressText.Text = getgenv().QuestProgress
        end
    end
end

-- === РАСШИРЕННЫЙ GUI ===
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "YBAFarmGUI"
ScreenGui.Parent = game.CoreGui

-- Основной фрейм
local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 300, 0, 350)
MainFrame.Position = UDim2.new(0, 20, 0, 20)
MainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
MainFrame.Parent = ScreenGui

-- Заголовок
local Title = Instance.new("TextLabel")
Title.Text = "YBA AUTOFARM v2.0"
Title.Size = UDim2.new(1, 0, 0, 40)
Title.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
Title.TextColor3 = Color3.fromRGB(255, 255, 0)
Title.Font = Enum.Font.GothamBold
Title.Parent = MainFrame

-- Информация о квесте
local QuestFrame = Instance.new("Frame")
QuestFrame.Size = UDim2.new(0.9, 0, 0, 60)
QuestFrame.Position = UDim2.new(0.05, 0, 0.12, 0)
QuestFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
QuestFrame.Parent = MainFrame

local QuestTitle = Instance.new("TextLabel")
QuestTitle.Text = "ТЕКУЩИЙ КВЕСТ:"
QuestTitle.Size = UDim2.new(1, 0, 0, 20)
QuestTitle.TextColor3 = Color3.fromRGB(200, 200, 255)
QuestTitle.BackgroundTransparency = 1
QuestTitle.Font = Enum.Font.Gotham
QuestTitle.Parent = QuestFrame

CurrentQuestLabel = Instance.new("TextLabel")
CurrentQuestLabel.Name = "CurrentQuestLabel"
CurrentQuestLabel.Text = getgenv().CurrentQuest
CurrentQuestLabel.Size = UDim2.new(1, 0, 0, 40)
CurrentQuestLabel.Position = UDim2.new(0, 0, 0, 20)
CurrentQuestLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
CurrentQuestLabel.BackgroundTransparency = 1
CurrentQuestLabel.TextWrapped = true
CurrentQuestLabel.Font = Enum.Font.GothamMedium
CurrentQuestLabel.Parent = QuestFrame

-- Прогресс бар
local ProgressFrame = Instance.new("Frame")
ProgressFrame.Size = UDim2.new(0.9, 0, 0, 30)
ProgressFrame.Position = UDim2.new(0.05, 0, 0.32, 0)
ProgressFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
ProgressFrame.Parent = MainFrame

ProgressBar = Instance.new("Frame")
ProgressBar.Name = "ProgressBar"
ProgressBar.Size = UDim2.new(0, 0, 1, 0)
ProgressBar.BackgroundColor3 = Color3.fromRGB(0, 200, 0)
ProgressBar.Parent = ProgressFrame

ProgressText = Instance.new("TextLabel")
ProgressText.Name = "ProgressText"
ProgressText.Text = getgenv().QuestProgress
ProgressText.Size = UDim2.new(1, 0, 1, 0)
ProgressText.TextColor3 = Color3.fromRGB(255, 255, 255)
ProgressText.BackgroundTransparency = 1
ProgressText.Font = Enum.Font.GothamBold
ProgressText.Parent = ProgressFrame

-- Статистика
local StatsFrame = Instance.new("Frame")
StatsFrame.Size = UDim2.new(0.9, 0, 0, 50)
StatsFrame.Position = UDim2.new(0.05, 0, 0.45, 0)
StatsFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
StatsFrame.Parent = MainFrame

local TargetLabel = Instance.new("TextLabel")
TargetLabel.Text = "Цель: Нет"
TargetLabel.Size = UDim2.new(1, 0, 0, 25)
TargetLabel.TextColor3 = Color3.fromRGB(255, 150, 150)
TargetLabel.BackgroundTransparency = 1
TargetLabel.Font = Enum.Font.Gotham
TargetLabel.Parent = StatsFrame

local KillsLabel = Instance.new("TextLabel")
KillsLabel.Text = "Убийств: 0/0"
KillsLabel.Size = UDim2.new(1, 0, 0, 25)
KillsLabel.Position = UDim2.new(0, 0, 0, 25)
KillsLabel.TextColor3 = Color3.fromRGB(150, 255, 150)
KillsLabel.BackgroundTransparency = 1
KillsLabel.Font = Enum.Font.Gotham
KillsLabel.Parent = StatsFrame

-- Статус
local StatusFrame = Instance.new("Frame")
StatusFrame.Size = UDim2.new(0.9, 0, 0, 40)
StatusFrame.Position = UDim2.new(0.05, 0, 0.62, 0)
StatusFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
StatusFrame.Parent = MainFrame

StatusLabel = Instance.new("TextLabel")
StatusLabel.Name = "StatusLabel"
StatusLabel.Text = "Статус: Ожидание"
StatusLabel.Size = UDim2.new(1, 0, 1, 0)
StatusLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
StatusLabel.BackgroundTransparency = 1
StatusLabel.Font = Enum.Font.GothamMedium
StatusLabel.Parent = StatusFrame

-- Кнопки управления
local ButtonsFrame = Instance.new("Frame")
ButtonsFrame.Size = UDim2.new(0.9, 0, 0, 100)
ButtonsFrame.Position = UDim2.new(0.05, 0, 0.78, 0)
ButtonsFrame.BackgroundTransparency = 1
ButtonsFrame.Parent = MainFrame

local ToggleBtn = Instance.new("TextButton")
ToggleBtn.Text = "⏸️ ПАУЗА"
ToggleBtn.Size = UDim2.new(0.48, 0, 0, 40)
ToggleBtn.Position = UDim2.new(0, 0, 0, 0)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleBtn.Font = Enum.Font.GothamBold
ToggleBtn.Parent = ButtonsFrame

local SafeModeBtn = Instance.new("TextButton")
SafeModeBtn.Text = "🛡️ БЕЗОПАСНЫЙ РЕЖИМ"
SafeModeBtn.Size = UDim2.new(0.48, 0, 0, 40)
SafeModeBtn.Position = UDim2.new(0.52, 0, 0, 0)
SafeModeBtn.BackgroundColor3 = Color3.fromRGB(50, 100, 200)
SafeModeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
SafeModeBtn.Font = Enum.Font.Gotham
SafeModeBtn.Parent = ButtonsFrame

local TeleportBtn = Instance.new("TextButton")
TeleportBtn.Text = "📍 ТЕЛЕПОРТ К ЦЕЛИ"
TeleportBtn.Size = UDim2.new(1, 0, 0, 40)
TeleportBtn.Position = UDim2.new(0, 0, 0, 50)
TeleportBtn.BackgroundColor3 = Color3.fromRGB(100, 50, 200)
TeleportBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
TeleportBtn.Font = Enum.Font.Gotham
TeleportBtn.Parent = ButtonsFrame

-- === ОБНОВЛЕНИЕ GUI ===
task.spawn(function()
    while task.wait(0.5) do
        -- Обновляем текущий квест
        if CurrentQuestLabel then
            CurrentQuestLabel.Text = getgenv().CurrentQuest
        end
        
        -- Обновляем цель
        if TargetLabel then
            TargetLabel.Text = "Цель: " .. (getgenv().CurrentTarget or "Нет")
        end
        
        -- Обновляем убийства
        if KillsLabel then
            KillsLabel.Text = "Убийств: " .. getgenv().KillCount .. "/" .. getgenv().TotalKills
        end
        
        -- Обновляем прогресс
        if ProgressText then
            ProgressText.Text = getgenv().QuestProgress
        end
    end
end)

-- === ОСНОВНОЙ ЦИКЛ СЮЖЕТА ===
function MainFarmLoop()
    while Config.AutoFarm do
        -- Получаем текущие квесты
        local QuestPanel = LocalPlayer.PlayerGui.HUD.Main.Frames.Quest.Quests
        
        -- Определяем текущий квест
        if QuestPanel:FindFirstChild("Help Giorno by Defeating Security Guards") then
            UpdateStatus("Квест: Security Guards")
            if AcceptQuestFromNPC("Giorno") then
                task.wait(2)
                if KillNPCContinuously("Security Guard", 3) then
                    task.wait(2)
                    AutoStoryDialogue()
                end
            end
            
        elseif QuestPanel:FindFirstChild("Defeat Leaky Eye Luca") then
            UpdateStatus("Квест: Leaky Eye Luca")
            if AcceptQuestFromNPC("Jotaro") then
                task.wait(2)
                if KillNPCContinuously("Leaky Eye Luca", 1) then
                    task.wait(2)
                    AutoStoryDialogue()
                end
            end
            
        elseif QuestPanel:FindFirstChild("Take down 3 vampires") then
            UpdateStatus("Квест: Vampires")
            if AcceptQuestFromNPC("William Zeppeli [Lvl. 25+]") then
                task.wait(2)
                if KillNPCContinuously("Vampire", 3) then
                    task.wait(2)
                    AutoStoryDialogue()
                end
            end
            
        else
            -- Если нет активных квестов, берем новый
            UpdateStatus("Поиск нового квеста...")
            if AcceptQuestFromNPC("Officer Sam [Lvl. 1+]") then
                task.wait(3)
            else
                task.wait(5)
            end
        end
        
        task.wait(1)
    end
end

-- === УПРАВЛЕНИЕ КНОПКАМИ ===
ToggleBtn.MouseButton1Click:Connect(function()
    Config.AutoFarm = not Config.AutoFarm
    if Config.AutoFarm then
        ToggleBtn.Text = "⏸️ ПАУЗА"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
        UpdateStatus("Возобновлено")
        task.spawn(MainFarmLoop)
    else
        ToggleBtn.Text = "▶️ ПРОДОЛЖИТЬ"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(50, 200, 50)
        UpdateStatus("Приостановлено")
    end
end)

SafeModeBtn.MouseButton1Click:Connect(function()
    Config.FarmDelay = Config.FarmDelay == 1 and 3 or 1
    SafeModeBtn.Text = Config.FarmDelay == 3 and "⚡ БЫСТРЫЙ РЕЖИМ" or "🛡️ БЕЗОПАСНЫЙ РЕЖИМ"
    UpdateStatus("Задержка: " .. Config.FarmDelay .. "с")
end)

TeleportBtn.MouseButton1Click:Connect(function()
    if getgenv().CurrentTarget then
        local npc = Workspace.Living:FindFirstChild(getgenv().CurrentTarget)
        if npc then
            SmartTeleport(npc.HumanoidRootPart.CFrame * CFrame.new(0, 0, 5), 0)
            UpdateStatus("Телепорт к цели")
        end
    else
        UpdateStatus("Нет активной цели")
    end
end)

-- === ГОРЯЧИЕ КЛАВИШИ ===
game:GetService("UserInputService").InputBegan:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.F5 then
        Config.AutoFarm = not Config.AutoFarm
        ToggleBtn.Text = Config.AutoFarm and "⏸️ ПАУЗА" or "▶️ ПРОДОЛЖИТЬ"
        ToggleBtn.BackgroundColor3 = Config.AutoFarm and Color3.fromRGB(200, 50, 50) or Color3.fromRGB(50, 200, 50)
    elseif input.KeyCode == Enum.KeyCode.F6 then
        Config.FarmDelay = Config.FarmDelay == 1 and 3 or 1
        SafeModeBtn.Text = Config.FarmDelay == 3 and "⚡ БЫСТРЫЙ РЕЖИМ" or "🛡️ БЕЗОПАСНЫЙ РЕЖИМ"
    elseif input.KeyCode == Enum.KeyCode.Delete then
        Config.AutoFarm = false
        ScreenGui:Destroy()
        UpdateStatus("Скрипт остановлен")
    end
end)

-- === ЗАПУСК ===
print("========================================")
print("YBA Autofarm v2.0 запущен!")
print("F5: Старт/Стоп | F6: Режим | DEL: Выход")
print("========================================")

UpdateStatus("Запуск автофарма...")
task.spawn(MainFarmLoop)
