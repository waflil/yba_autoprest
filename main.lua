-- ======================================================================
-- YBA (Your Bizarre Adventure) - ПОЛНЫЙ АВТОФАРМ СЮЖЕТА
-- Версия 1.0 | Создан на основе данных сканирования
-- ======================================================================

-- === НАСТРОЙКИ ===
getgenv().AutoFarm = true -- Автоматический запуск
getgenv().AttackRange = 15 -- Дистанция атаки
getgenv().FarmSpeed = 0.5 -- Задержка между действиями (сек)

-- === СЕРВИСЫ ===
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")

-- === СПИСКИ ОБЪЕКТОВ ИЗ СКАНИРОВАНИЯ ===
local QuestNPCs = {
    "Officer Sam [Lvl. 1+]",
    "Deputy Bertrude [Lvl. 10+]",
    "Abbacchio's Partner [Lvl 15+]",
    "Homeless Man Jill [Lvl. 15+]",
    "Dracula [Lvl. 20+]",
    "Darius, The Executioner [Lvl. 20+]",
    "William Zeppeli [Lvl. 25+]",
    "Doppio [Lvl. 30+]",
    "Kars [Lvl. 30+]",
    "Dio [Lvl. 35+]",
    "Pucci [Lvl. 40+]"
}

local EnemyTypes = {
    "Security Guard",
    "Thug",
    "Alpha Thug",
    "Corrupt Police",
    "Vampire",
    "Zombie Henchman"
}

local StoryNPCs = {
    "Jotaro",
    "Dio",
    "Giorno",
    "Bucciarati",
    "Koichi",
    "Lisa Lisa"
}

-- === ВСПОМОГАТЕЛЬНЫЕ ФУНКЦИИ ===

-- Функция 1A: Поиск NPC по имени
function findNPC(npcName)
    for _, npc in pairs(Workspace.Dialogues:GetChildren()) do
        if npc.Name == npcName and npc:FindFirstChild("Humanoid") then
            return npc
        end
    end
    return nil
end

-- Функция 1B: Поиск ближайшего врага
function findNearestEnemy()
    local closest = nil
    local maxDist = math.huge
    
    for _, enemy in pairs(Workspace.Living:GetChildren()) do
        if enemy:FindFirstChild("Humanoid") and enemy.Humanoid.Health > 0 then
            for _, enemyType in pairs(EnemyTypes) do
                if enemy.Name == enemyType then
                    local dist = (HumanoidRootPart.Position - enemy.HumanoidRootPart.Position).Magnitude
                    if dist < maxDist then
                        maxDist = dist
                        closest = enemy
                    end
                end
            end
        end
    end
    return closest
end

-- Функция 1C: Взаимодействие с ProximityPrompt
function interactWithPrompt(object)
    if object then
        local prompt = object:FindFirstChildWhichIsA("ProximityPrompt")
        if prompt then
            fireproximityprompt(prompt)
            return true
        end
    end
    return false
end

-- === ОСНОВНОЙ ЦИКЛ АВТОФАРМА ===
spawn(function()
    while getgenv().AutoFarm do
        task.wait(getgenv().FarmSpeed)
        
        -- ШАГ 2A: Проверка наличия активного квеста через интерфейс
        local questActive = false
        local hud = LocalPlayer.PlayerGui:FindFirstChild("HUD")
        if hud then
            for _, element in pairs(hud:GetDescendants()) do
                if element:IsA("TextLabel") and (element.Text:match("Quest") or element.Text:match("Квест")) then
                    questActive = true
                    break
                end
            end
        end
        
        -- ШАГ 2B: Если нет активного квеста - ищем NPC для взятия
        if not questActive then
            for _, npcName in pairs(QuestNPCs) do
                local npc = findNPC(npcName)
                if npc and getgenv().AutoFarm then
                    -- Телепорт к NPC
                    HumanoidRootPart.CFrame = npc.HumanoidRootPart.CFrame * CFrame.new(0, 0, 4)
                    task.wait(0.7)
                    
                    -- Взаимодействие для взятия квеста
                    if interactWithPrompt(npc) then
                        print("[AUTO] Взят квест у: " .. npc.Name)
                        task.wait(2)
                        break
                    end
                end
            end
        end
        
        -- ШАГ 3A: Поиск и убийство врагов для квеста
        local enemy = findNearestEnemy()
        if enemy and getgenv().AutoFarm then
            -- Телепорт к врагу на дистанцию атаки
            local enemyPos = enemy.HumanoidRootPart.Position
            HumanoidRootPart.CFrame = CFrame.new(enemyPos + Vector3.new(0, 0, getgenv().AttackRange))
            
            -- ШАГ 3B: Атака врага
            task.wait(0.3)
            local tool = Character:FindFirstChildOfClass("Tool") or Character:FindFirstChildOfClass("HopperBin")
            if tool then
                for i = 1, 10 do -- Серия атак
                    if not getgenv().AutoFarm then break end
                    tool:Activate()
                    task.wait(0.2)
                end
            else
                -- Базовая атака, если нет инструмента
                game:GetService("VirtualInputManager"):SendKeyEvent(true, Enum.KeyCode.E, false, game)
                task.wait(0.5)
                game:GetService("VirtualInputManager"):SendKeyEvent(false, Enum.KeyCode.E, false, game)
            end
            
            -- ШАГ 3C: Ожидание смерти врага
            repeat
                task.wait(0.5)
            until not enemy or enemy.Humanoid.Health <= 0 or not getgenv().AutoFarm
            
            if enemy and enemy.Humanoid.Health <= 0 then
                print("[AUTO] Убит враг: " .. enemy.Name)
            end
        end
        
        -- ШАГ 4: Проверка завершения квеста
        task.wait(1)
        
        -- ШАГ 4A: Поиск NPC для сдачи квеста
        for _, npcName in pairs(QuestNPCs) do
            local npc = findNPC(npcName)
            if npc and getgenv().AutoFarm then
                HumanoidRootPart.CFrame = npc.HumanoidRootPart.CFrame * CFrame.new(0, 0, 4)
                task.wait(0.7)
                
                -- ШАГ 4B: Попытка сдачи квеста
                if interactWithPrompt(npc) then
                    print("[AUTO] Попытка сдать квест: " .. npc.Name)
                    task.wait(3)
                    break
                end
            end
        end
        
        -- ШАГ 5: Защита от афк
        game:GetService("VirtualInputManager"):SendKeyEvent(true, Enum.KeyCode.W, false, game)
        task.wait(0.1)
        game:GetService("VirtualInputManager"):SendKeyEvent(false, Enum.KeyCode.W, false, game)
    end
end)

-- === GUI ДЛЯ УПРАВЛЕНИЯ ===
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "AutoFarmGUI"
screenGui.Parent = game.CoreGui

local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0, 200, 0, 150)
mainFrame.Position = UDim2.new(0, 10, 0, 10)
mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
mainFrame.Parent = screenGui

local title = Instance.new("TextLabel")
title.Name = "Title"
title.Text = "YBA AutoFarm v1.0"
title.Size = UDim2.new(1, 0, 0, 30)
title.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.Parent = mainFrame

local toggleBtn = Instance.new("TextButton")
toggleBtn.Name = "ToggleButton"
toggleBtn.Text = "ОСТАНОВИТЬ"
toggleBtn.Size = UDim2.new(0.9, 0, 0, 40)
toggleBtn.Position = UDim2.new(0.05, 0, 0.25, 0)
toggleBtn.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
toggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleBtn.Parent = mainFrame

local statusLabel = Instance.new("TextLabel")
statusLabel.Name = "StatusLabel"
statusLabel.Text = "СТАТУС: РАБОТАЕТ"
statusLabel.Size = UDim2.new(0.9, 0, 0, 30)
statusLabel.Position = UDim2.new(0.05, 0, 0.6, 0)
statusLabel.BackgroundColor3 = Color3.fromRGB(0, 100, 0)
statusLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
statusLabel.Parent = mainFrame

-- Обработчик кнопки
toggleBtn.MouseButton1Click:Connect(function()
    getgenv().AutoFarm = not getgenv().AutoFarm
    if getgenv().AutoFarm then
        toggleBtn.Text = "ОСТАНОВИТЬ"
        toggleBtn.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
        statusLabel.Text = "СТАТУС: РАБОТАЕТ"
        statusLabel.BackgroundColor3 = Color3.fromRGB(0, 100, 0)
        print("[AUTO] Автофарм возобновлен.")
    else
        toggleBtn.Text = "ЗАПУСТИТЬ"
        toggleBtn.BackgroundColor3 = Color3.fromRGB(50, 200, 50)
        statusLabel.Text = "СТАТУС: ОСТАНОВЛЕН"
        statusLabel.BackgroundColor3 = Color3.fromRGB(100, 0, 0)
        print("[AUTO] Автофарм остановлен.")
    end
end)

-- === ГОРЯЧИЕ КЛАВИШИ ===
game:GetService("UserInputService").InputBegan:Connect(function(input)
    -- F5: Быстрый старт/стоп
    if input.KeyCode == Enum.KeyCode.F5 then
        getgenv().AutoFarm = not getgenv().AutoFarm
        toggleBtn.Text = getgenv().AutoFarm and "ОСТАНОВИТЬ" or "ЗАПУСТИТЬ"
        toggleBtn.BackgroundColor3 = getgenv().AutoFarm and Color3.fromRGB(255, 50, 50) or Color3.fromRGB(50, 200, 50)
    end
    
    -- Delete: Экстренная остановка и удаление GUI
    if input.KeyCode == Enum.KeyCode.Delete then
        getgenv().AutoFarm = false
        screenGui:Destroy()
        print("[ЭКСТРЕННАЯ ОСТАНОВКА] GUI удален.")
    end
end)

-- === ИНИЦИАЛИЗАЦИЯ ===
print("==========================================")
print("YBA AutoFarm v1.0 успешно загружен!")
print("Управление:")
print("  - F5: Быстрый старт/стоп")
print("  - Delete: Экстренная остановка")
print("  - GUI: В левом верхнем углу")
print("==========================================")