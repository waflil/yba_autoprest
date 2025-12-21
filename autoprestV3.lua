-- ======================================================================
-- YBA AUTO STORY (Xeno Executor Compatible)
-- Без getgenv, task.spawn, firesignal, CoreGui
-- ======================================================================

-- === НАСТРОЙКИ ===
local AutoFarm = true
local AttackRange = 4
local CombatTimeout = 60

-- === ИНИЦИАЛИЗАЦИЯ ===
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")

-- === СОСТОЯНИЕ ===
local StoryPhase = 1
local function Log(msg)
    warn("[YBA AUTO] " .. msg)
end

-- === ПОЛЕЗНЫЕ ФУНКЦИИ ===

local function FindNPC(name)
    return Workspace.Dialogues:FindFirstChild(name) or Workspace.Living:FindFirstChild(name)
end

local function TeleportTo(cframe)
    if cframe then
        HumanoidRootPart.CFrame = cframe
    end
end

local function WaitForChild(parent, name, timeout)
    local obj = parent:FindFirstChild(name)
    if obj then return obj end
    local start = tick()
    while tick() - start < (timeout or 10) do
        obj = parent:FindFirstChild(name)
        if obj then return obj end
        wait(0.2)
    end
    return nil
end

-- Имитация клика по кнопке (без firesignal)
local function ClickButton(button)
    if button and button.MouseButton1Click then
        local conns = {}
        for _, conn in pairs(button.MouseButton1Click:GetConnections()) do
            table.insert(conns, conn)
        end
        for _, conn in ipairs(conns) do
            conn.Function()
        end
    end
end

-- Диалог: автоматическое нажатие (макс 10 раз)
local function AutoClickDialogue()
    for i = 1, 10 do
        wait(0.7)
        local gui = LocalPlayer.PlayerGui:FindFirstChild("DialogueGui")
        if not gui then break end
        local frame = gui:FindFirstChild("Frame")
        if frame then
            local cont = frame:FindFirstChild("ClickContinue")
            if cont then
                ClickButton(cont)
            end
        end
    end
end

-- Диалог с выбором (для Мисты)
local function DialogueWithChoices(choices)
    for _, choice in ipairs(choices) do
        wait(0.8)
        local gui = LocalPlayer.PlayerGui:FindFirstChild("DialogueGui")
        if not gui then break end
        local frame = gui:FindFirstChild("Frame")
        if frame then
            if choice == "left" then
                ClickButton(frame:FindFirstChild("LeftButton"))
            elseif choice == "right" then
                ClickButton(frame:FindFirstChild("RightButton"))
            end
        end
    end
    wait(1)
end

-- Подход и диалог
local function TalkTo(npcName, choices)
    local npc = FindNPC(npcName)
    if not npc or not npc:FindFirstChild("HumanoidRootPart") then
        Log("NPC не найден: " .. tostring(npcName))
        return false
    end

    Log("Подхожу к: " .. npcName)
    TeleportTo(npc.HumanoidRootPart.CFrame * CFrame.new(0, 0, 5))
    wait(0.8)

    local prompt = npc:FindFirstChildWhichIsA("ProximityPrompt")
    if prompt and prompt.Enabled then
        -- Имитация активации промпта
        if Character and Character:FindFirstChild("RemoteEvent") then
            Character.RemoteEvent:FireServer("ProximityPrompt", prompt)
        end
    end

    wait(1.5)

    if choices then
        DialogueWithChoices(choices)
    else
        AutoClickDialogue()
    end
    return true
end

-- Убийство цели (без фонового телепорта — Xeno не любит spawn)
local function KillTarget(npcName, count)
    count = count or 1
    for i = 1, count do
        Log("Охота на: " .. npcName .. " (" .. i .. "/" .. count .. ")")

        local npc = WaitForChild(Workspace.Living, npcName, 15)
        if not npc then
            Log("Цель не появилась")
            return false
        end

        local hrp = npc:FindFirstChild("HumanoidRootPart")
        if not hrp then return false end

        local start = tick()
        while tick() - start < CombatTimeout do
            if not npc.Parent or not npc:FindFirstChild("Humanoid") or npc.Humanoid.Health <= 0 then
                break
            end

            -- Телепорт КАЖДЫЙ РАЗ перед атакой (Xeno: нет фонового потока!)
            TeleportTo(hrp.CFrame * CFrame.new(0, 0, AttackRange))

            -- Атака
            if Character:FindFirstChild("SummonedStand") and Character.SummonedStand.Value then
                pcall(function()
                    Character.RemoteFunction:InvokeServer("Attack", "m1")
                end)
            else
                -- Нажать E
                pcall(function()
                    game:GetService("VirtualInputManager"):SendKeyEvent(true, Enum.KeyCode.E, false, game)
                    wait(0.05)
                    game:GetService("VirtualInputManager"):SendKeyEvent(false, Enum.KeyCode.E, false, game)
                end)
            end
            wait(0.15)
        end

        if npc and npc.Parent and npc:FindFirstChild("Humanoid") and npc.Humanoid.Health > 0 then
            Log("Не удалось убить " .. npcName)
            return false
        end
        wait(1)
    end
    return true
end

-- === ОСНОВНОЙ ЦИКЛ ===
local function RunStory()
    while AutoFarm do
        Log("Фаза: " .. StoryPhase)

        if StoryPhase == 1 then
            if KillTarget("Corrupt Police", 5) then
                wait(2)
                TalkTo("Giorno")
                StoryPhase = 2
            end

        elseif StoryPhase == 2 then
            TalkTo("Koichi")
            StoryPhase = 3

        elseif StoryPhase == 3 then
            -- Ищем ближайшего Giorno (у парка)
            local giornos = {}
            for _, g in pairs(Workspace.Dialogues:GetChildren()) do
                if g.Name == "Giorno" and g:FindFirstChild("HumanoidRootPart") then
                    table.insert(giornos, g)
                end
            end
            table.sort(giornos, function(a, b)
                return (a.HumanoidRootPart.Position - HumanoidRootPart.Position).Magnitude <
                       (b.HumanoidRootPart.Position - HumanoidRootPart.Position).Magnitude
            end)
            if #giornos > 0 then
                local giorno = giornos[1]
                TeleportTo(giorno.HumanoidRootPart.CFrame * CFrame.new(0, 0, 5))
                wait(0.8)
                local prompt = giorno:FindFirstChildWhichIsA("ProximityPrompt")
                if prompt then
                    Character.RemoteEvent:FireServer("ProximityPrompt", prompt)
                end
                wait(2)
                if KillTarget("Leaky Eye Luca") then
                    StoryPhase = 4
                end
            end

        elseif StoryPhase == 4 then
            TalkTo("Giorno")
            if KillTarget("Bucciarati") then
                StoryPhase = 5
            end

        elseif StoryPhase == 5 then
            TalkTo("Bucciarati")
            StoryPhase = 6

        elseif StoryPhase == 6 then
            TalkTo("Giorno")
            StoryPhase = 7

        elseif StoryPhase == 7 then
            TalkTo("Fugo")
            TalkTo("Mista", {"left", "left", "right", "left", "left"}) -- 2+2 = не 4!
            StoryPhase = 8

        elseif StoryPhase == 8 then
            TalkTo("Narancia")
            TalkTo("Abbacchio")
            TalkTo("Bucciarati")
            StoryPhase = 9

        elseif StoryPhase == 9 then
            TalkTo("Trish")
            if KillTarget("Fugo") then
                TalkTo("Trish")
                StoryPhase = 10
            end

        elseif StoryPhase == 10 then
            if KillTarget("Pesci") then
                TalkTo("Trish")
                StoryPhase = 11
            end

        elseif StoryPhase == 11 then
            TalkTo("Mista")
            StoryPhase = 12

        elseif StoryPhase == 12 then
            if KillTarget("Ghiaccio") then
                TalkTo("Mista")
                StoryPhase = 13
            end

        elseif StoryPhase == 13 then
            TalkTo("Bucciarati")
            TalkTo("Giorno")
            StoryPhase = 14

        elseif StoryPhase == 14 then
            if KillTarget("Diavolo") then
                TalkTo("Giorno")
                wait(10)
                StoryPhase = 15
            end

        elseif StoryPhase == 15 then
            TalkTo("Prestige Master Rin")
            wait(5)
            StoryPhase = 1 -- Начать заново!
        end

        wait(1)
    end
end

-- === УПРАВЛЕНИЕ ГОРЯЧИМИ КЛАВИШАМИ ===
UserInputService.InputBegan:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.F5 then
        AutoFarm = not AutoFarm
        Log(AutoFarm and "ЗАПУЩЕНО" or "ПАУЗА")
        if AutoFarm then
            spawn(RunStory) -- spawn в Xeno может работать как pcall в отдельном потоке
        end
    elseif input.KeyCode == Enum.KeyCode.Delete then
        AutoFarm = false
        Log("Остановлено")
    end
end)

Log("YBA AUTO STORY (Xeno) загружен. Нажмите F5 для запуска.")
