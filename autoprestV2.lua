-- ======================================================================
-- YBA AUTO STORY & PRESTIGE v1.0 (Полный сюжет + Миста 2+2 + Престиж)
-- Поддержка всех этапов до Diavolo и автоматический перезапуск
-- ======================================================================

getgenv().Config = {
    AutoFarm = true,
    StandList = {
        ["The World"] = true,
        ["Star Platinum"] = true,
        ["Crazy Diamond"] = true
    },
    AttackRange = 4,
    WaitForDialogue = 3,
    CombatTimeout = 60 -- макс 60 сек на убийство босса
}

-- === ИНИЦИАЛИЗАЦИЯ ===
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RS = game:GetService("ReplicatedStorage")
local UIS = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")

-- === ГЛОБАЛЬНЫЕ ПЕРЕМЕННЫЕ ===
getgenv().StoryPhase = 1
getgenv().CurrentAction = "Ожидание запуска..."
getgenv().CurrentTarget = nil

-- === ВСПОМОГАТЕЛЬНЫЕ ФУНКЦИИ ===

function UpdateStatus(msg)
    getgenv().CurrentAction = msg
    print("[YBA STORY] " .. msg)
end

function SmartTeleport(cframe, delay)
    if not cframe then return end
    HumanoidRootPart.CFrame = cframe
    if delay then task.wait(delay) end
end

function FindNPC(name, folder)
    local f = folder or Workspace
    return f:FindFirstChild(name) or f.Living:FindFirstChild(name) or f.Dialogues:FindFirstChild(name)
end

function GetNearbyGiorno()
    local giornos = {}
    for _, npc in pairs(Workspace.Dialogues:GetChildren()) do
        if npc.Name == "Giorno" then
            table.insert(giornos, npc)
        end
    end
    table.sort(giornos, function(a, b)
        return a.HumanoidRootPart and b.HumanoidRootPart and
               (a.HumanoidRootPart.Position - HumanoidRootPart.Position).Magnitude <
               (b.HumanoidRootPart.Position - HumanoidRootPart.Position).Magnitude
    end)
    return giornos[1]
end

function TalkTo(npcName, choices)
    local npc = FindNPC(npcName)
    if not npc or not npc:FindFirstChild("HumanoidRootPart") then
        UpdateStatus("NPC не найден: " .. tostring(npcName))
        return false
    end

    UpdateStatus("Подхожу к: " .. npcName)
    SmartTeleport(npc.HumanoidRootPart.CFrame * CFrame.new(0, 0, 5), 1)

    local prompt = npc:FindFirstChildWhichIsA("ProximityPrompt")
    if prompt then
        fireproximityprompt(prompt)
    end

    task.wait(1)

    if choices then
        for _, choice in ipairs(choices) do
            task.wait(0.8)
            local gui = LocalPlayer.PlayerGui:FindFirstChild("DialogueGui")
            if gui then
                local frame = gui:FindFirstChild("Frame")
                if frame then
                    if choice == "left" and frame:FindFirstChild("LeftButton") then
                        firesignal(frame.LeftButton.MouseButton1Click)
                    elseif choice == "right" and frame:FindFirstChild("RightButton") then
                        firesignal(frame.RightButton.MouseButton1Click)
                    end
                end
            end
        end
    else
        -- Просто завершить диалог (автоклик)
        for i = 1, 8 do
            task.wait(0.6)
            local gui = LocalPlayer.PlayerGui:FindFirstChild("DialogueGui")
            if not gui then break end
            local frame = gui:FindFirstChild("Frame")
            if frame and frame:FindFirstChild("ClickContinue") then
                firesignal(frame.ClickContinue.MouseButton1Click)
            end
        end
    end

    task.wait(1.5)
    return true
end

function KillTarget(npcName, count)
    count = count or 1
    for i = 1, count do
        UpdateStatus("Охота на: " .. npcName .. " (" .. i .. "/" .. count .. ")")
        getgenv().CurrentTarget = npcName

        local npc = Workspace.Living:WaitForChild(npcName, 15)
        if not npc then
            UpdateStatus("Цель не появилась: " .. npcName)
            return false
        end

        local hrp = npc:FindFirstChild("HumanoidRootPart") or npc:FindFirstChild("RootPart")
        if not hrp then return false end

        local isDead = false
        local hold = task.spawn(function()
            while npc and npc.Parent and hrp and hrp.Parent and not isDead and Config.AutoFarm do
                if HumanoidRootPart and HumanoidRootPart.Parent then
                    local look = CFrame.lookAt(hrp.Position, hrp.Position + hrp.CFrame.LookVector)
                    HumanoidRootPart.CFrame = look * CFrame.new(0, 0, Config.AttackRange)
                end
                task.wait(0.05)
            end
        end)

        task.wait(0.3)
        local start = tick()
        while tick() - start < Config.CombatTimeout do
            if not npc or not npc.Parent or not npc:FindFirstChild("Humanoid") or npc.Humanoid.Health <= 0 then
                isDead = true
                break
            end

            if Character.SummonedStand and Character.SummonedStand.Value then
                pcall(function()
                    Character.RemoteFunction:InvokeServer("Attack", "m1")
                end)
            else
                local vim = game:GetService("VirtualInputManager")
                vim:SendKeyEvent(true, Enum.KeyCode.E, false, game)
                task.wait(0.05)
                vim:SendKeyEvent(false, Enum.KeyCode.E, false, game)
            end
            task.wait(0.1)
        end

        hold:Cancel()
        isDead = true
        if npc and npc:FindFirstChild("Humanoid") and npc.Humanoid.Health <= 0 then
            task.wait(1)
        else
            UpdateStatus("Не удалось убить " .. npcName)
            return false
        end
    end
    getgenv().CurrentTarget = nil
    return true
end

-- === ОСНОВНОЙ ЦИКЛ СЮЖЕТА ===
function RunStory()
    while Config.AutoFarm do
        UpdateStatus("Фаза: " .. getgenv().StoryPhase)

        if getgenv().StoryPhase == 1 then
            -- Убить 5 Corrupt Police → Giorno #1
            if KillTarget("Corrupt Police", 5) then
                task.wait(2)
                TalkTo("Giorno")
                getgenv().StoryPhase = 2
            end

        elseif getgenv().StoryPhase == 2 then
            -- Поговорить с Koichi
            TalkTo("Koichi")
            getgenv().StoryPhase = 3

        elseif getgenv().StoryPhase == 3 then
            -- Giorno #2 (у парка) → Luca
            local giorno = GetNearbyGiorno()
            if giorno then
                SmartTeleport(giorno.HumanoidRootPart.CFrame * CFrame.new(0, 0, 5), 1)
                fireproximityprompt(giorno:FindFirstChildWhichIsA("ProximityPrompt"))
                task.wait(2)
                if KillTarget("Leaky Eye Luca") then
                    getgenv().StoryPhase = 4
                end
            end

        elseif getgenv().StoryPhase == 4 then
            -- Giorno #3 → убить Bucciarati
            TalkTo("Giorno")
            if KillTarget("Bucciarati") then
                getgenv().StoryPhase = 5
            end

        elseif getgenv().StoryPhase == 5 then
            -- Поговорить с Bucciarati (дружелюбный)
            TalkTo("Bucciarati")
            getgenv().StoryPhase = 6

        elseif getgenv().StoryPhase == 6 then
            -- Giorno #4 (у вокзала)
            TalkTo("Giorno")
            getgenv().StoryPhase = 7

        elseif getgenv().StoryPhase == 7 then
            -- Fugo → Mista (с 2+2!)
            TalkTo("Fugo")
            TalkTo("Mista", {"left", "left", "right", "left", "left"}) -- ← НЕ 4!
            getgenv().StoryPhase = 8

        elseif getgenv().StoryPhase == 8 then
            -- Narancia → Abbacchio → Bucciarati #3
            TalkTo("Narancia")
            TalkTo("Abbacchio")
            TalkTo("Bucciarati")
            getgenv().StoryPhase = 9

        elseif getgenv().StoryPhase == 9 then
            -- Trish → Enemy Fugo → Trish
            TalkTo("Trish")
            if KillTarget("Fugo") then
                TalkTo("Trish")
                getgenv().StoryPhase = 10
            end

        elseif getgenv().StoryPhase == 10 then
            -- Pesci → Trish
            if KillTarget("Pesci") then
                TalkTo("Trish")
                getgenv().StoryPhase = 11
            end

        elseif getgenv().StoryPhase == 11 then
            -- Mista #2 (у вокзала)
            TalkTo("Mista")
            getgenv().StoryPhase = 12

        elseif getgenv().StoryPhase == 12 then
            -- Ghiaccio → Mista
            if KillTarget("Ghiaccio") then
                TalkTo("Mista")
                getgenv().StoryPhase = 13
            end

        elseif getgenv().StoryPhase == 13 then
            -- Bucciarati #4 (у моста) → Giorno #5 (тюрьма)
            TalkTo("Bucciarati")
            TalkTo("Giorno")
            getgenv().StoryPhase = 14

        elseif getgenv().StoryPhase == 14 then
            -- Diavolo → финал
            if KillTarget("Diavolo") then
                TalkTo("Giorno")
                task.wait(10) -- Ждём катсцену
                getgenv().StoryPhase = 15
            end

        elseif getgenv().StoryPhase == 15 then
            -- Престиж
            TalkTo("Prestige Master Rin")
            task.wait(5)
            getgenv().StoryPhase = 1 -- Начать заново!
        end

        task.wait(1)
    end
end

-- === GUI ===
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "YBAStoryGUI"
ScreenGui.Parent = game.CoreGui

local Frame = Instance.new("Frame")
Frame.Size = UDim2.new(0, 300, 0, 150)
Frame.Position = UDim2.new(0, 20, 0, 20)
Frame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
Frame.Parent = ScreenGui

local Title = Instance.new("TextLabel")
Title.Text = "YBA AUTO STORY v1.0"
Title.Size = UDim2.new(1, 0, 0, 30)
Title.BackgroundTransparency = 1
Title.TextColor3 = Color3.fromRGB(255, 255, 100)
Title.Font = Enum.Font.GothamBold
Title.Parent = Frame

local StatusLabel = Instance.new("TextLabel")
StatusLabel.Name = "StatusLabel"
StatusLabel.Size = UDim2.new(0.9, 0, 0, 80)
StatusLabel.Position = UDim2.new(0.05, 0, 0.25, 0)
StatusLabel.BackgroundTransparency = 1
StatusLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
StatusLabel.TextWrapped = true
StatusLabel.Font = Enum.Font.Gotham
StatusLabel.Parent = Frame

-- Обновление статуса
task.spawn(function()
    while task.wait(0.5) do
        if StatusLabel then
            StatusLabel.Text = "Текущее действие:\n" .. getgenv().CurrentAction
        end
    end
end)

-- Горячие клавиши
UIS.InputBegan:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.F5 then
        Config.AutoFarm = not Config.AutoFarm
        UpdateStatus(Config.AutoFarm and "Запущено" or "Пауза")
        if Config.AutoFarm then
            task.spawn(RunStory)
        end
    elseif input.KeyCode == Enum.KeyCode.Delete then
        Config.AutoFarm = false
        ScreenGui:Destroy()
        UpdateStatus("Скрипт остановлен")
    end
end)

-- === СТАРТ ===
print("==========================================")
print("YBA AUTO STORY запущен!")
print("F5 — Старт/Пауза | Delete — Выход")
print("Подходит для полного прохождения + престижа")
print("==========================================")
UpdateStatus("Готов. Нажмите F5 для запуска.")
