-- ======================================================================
-- YBA Autofarm Ultimate v2.1 (ПОЛНОСТЬЮ ИСПРАВЛЕН ДЛЯ СЮЖЕТА)
-- Работает с твоей сюжетной линией: Giorno → Koichi → Giorno → Luca → ...
-- ======================================================================

-- === КОНФИГУРАЦИЯ ===
getgenv().Config = {
    AutoFarm = true,
    StandList = {
        ["The World"] = true,
        ["Star Platinum"] = true,
        ["Crazy Diamond"] = true
    },
    AttackRange = 4, -- уменьшено для точности
    WaitForDialogue = 3,
    CombatCheckInterval = 0.12
}

-- === ИНИЦИАЛИЗАЦИЯ ===
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")

-- === ГЛОБАЛЬНЫЕ ПЕРЕМЕННЫЕ ===
getgenv().CurrentTarget = nil
getgenv().CurrentQuest = "Ожидание квеста..."
getgenv().QuestProgress = "0%"
getgenv().KillCount = 0
getgenv().TotalKills = 0

-- === ФУНКЦИИ ===

function SmartTeleport(targetCFrame, waitTime)
    if not targetCFrame then return false end
    HumanoidRootPart.CFrame = targetCFrame
    task.wait(waitTime or 1)
    return true
end

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

function EndDialogueWithWait(NPC, Dialogue, Option)
    Character.RemoteEvent:FireServer("EndDialogue", {
        ["NPC"] = NPC,
        ["Dialogue"] = Dialogue,
        ["Option"] = Option
    })
    task.wait(1)
    if WaitForDialogue() then
        for i = 1, 5 do
            local gui = LocalPlayer.PlayerGui:FindFirstChild("DialogueGui")
            if gui and gui:FindFirstChild("Frame") and gui.Frame:FindFirstChild("ClickContinue") then
                pcall(function() firesignal(gui.Frame.ClickContinue.MouseButton1Click) end)
            end
            task.wait(0.5)
        end
        return true
    end
    return false
end

function AutoStoryDialogue()
    local Story = {
        ["Quests"] = {"#1", "#1", "#1", "#2", "#3", "#3", "#3", "#4", "#5", "#6", "#7", "#8", "#9", "#10", "#11", "#11", "#12", "#14"},
        ["Dialogues"] = {"Dialogue2", "Dialogue6", "Dialogue6", "Dialogue3", "Dialogue3", "Dialogue3", "Dialogue6", "Dialogue3", "Dialogue5", "Dialogue5", "Dialogue5", "Dialogue4", "Dialogue7", "Dialogue6", "Dialogue8", "Dialogue11", "Dialogue3", "Dialogue2"}
    }
    for i = 1, 18 do
        EndDialogueWithWait("Storyline " .. Story["Quests"][i], Story["Dialogues"][i], "Option1")
        task.wait(0.3)
    end
end

function FindDialogueNPC(npcName)
    local dialogues = Workspace:FindFirstChild("Dialogues")
    if dialogues then
        for _, npc in pairs(dialogues:GetChildren()) do
            if npc.Name == npcName then return npc end
        end
    end
    return Workspace.Living:FindFirstChild(npcName)
end

-- === ИСПРАВЛЕНО: поиск ближайшего Giorno ===
function AcceptQuestFromNPC(npcName)
    local npc

    if npcName == "Giorno" then
        local giornos = {}
        for _, g in pairs(Workspace.Dialogues:GetChildren()) do
            if g.Name == "Giorno" and g:FindFirstChild("HumanoidRootPart") then
                table.insert(giornos, g)
            end
        end
        if #giornos == 0 then
            UpdateStatus("Джорно не найден")
            return false
        end
        table.sort(giornos, function(a, b)
            return (a.HumanoidRootPart.Position - HumanoidRootPart.Position).Magnitude <
                   (b.HumanoidRootPart.Position - HumanoidRootPart.Position).Magnitude
        end)
        npc = giornos[1]
    else
        npc = FindDialogueNPC(npcName)
    end

    if not npc then
        UpdateStatus("NPC не найден: " .. npcName)
        return false
    end

    UpdateStatus("Подхожу к: " .. npcName)
    SmartTeleport(npc.HumanoidRootPart.CFrame * CFrame.new(0, 0, 5), 2)

    local prompt = npc:FindFirstChildWhichIsA("ProximityPrompt")
    if prompt then
        pcall(fireproximityprompt, prompt)
        UpdateStatus("Взаимодействие с " .. npcName)
        task.wait(2)
        return true
    end
    return false
end

-- === ИСПРАВЛЕНО: надёжное убийство ===
function KillNPCContinuously(npcName, requiredKills)
    UpdateStatus("Охота на: " .. npcName)
    getgenv().CurrentTarget = npcName
    getgenv().KillCount = 0
    getgenv().TotalKills = requiredKills or 1

    local kills = 0
    for kill = 1, requiredKills do
        local npc = Workspace.Living:WaitForChild(npcName, 15)
        if not npc then break end

        local hrp = npc:FindFirstChild("HumanoidRootPart")
        if not hrp then break end

        local battleStart = tick()
        while npc and npc.Parent and hrp and hrp.Parent and Config.AutoFarm do
            if not npc:FindFirstChild("Humanoid") or npc.Humanoid.Health <= 0 then
                kills = kills + 1
                getgenv().KillCount = kills
                UpdateStatus("Убито " .. kills .. "/" .. requiredKills)
                task.wait(1)
                break
            end

            if tick() - battleStart > 50 then break end

            -- Удержание позиции ЗА СПИНОЙ + наведение
            if HumanoidRootPart and HumanoidRootPart.Parent then
                local dir = (hrp.Position - HumanoidRootPart.Position).unit
                HumanoidRootPart.CFrame = CFrame.lookAt(HumanoidRootPart.Position, HumanoidRootPart.Position + dir) * CFrame.new(0, 0, Config.AttackRange)
            end

            -- Атака
            if Character.SummonedStand and Character.SummonedStand.Value then
                pcall(function() Character.RemoteFunction:InvokeServer("Attack", "m1") end)
            else
                local vim = game:GetService("VirtualInputManager")
                vim:SendKeyEvent(true, Enum.KeyCode.E, false, game)
                task.wait(0.05)
                vim:SendKeyEvent(false, Enum.KeyCode.E, false, game)
            end

            task.wait(Config.CombatCheckInterval)
        end
    end

    getgenv().CurrentTarget = nil
    return kills >= requiredKills
end

function UpdateStatus(message)
    getgenv().CurrentQuest = message
    if StatusLabel then StatusLabel.Text = "Статус: " .. message end
    print("[AUTO] " .. message)
end

function UpdateProgress(current, total)
    if total > 0 then
        local p = math.floor((current / total) * 100)
        getgenv().QuestProgress = p .. "%"
        if ProgressBar then ProgressBar.Size = UDim2.new(p / 100, 0, 1, 0) end
        if ProgressText then ProgressText.Text = getgenv().QuestProgress end
    end
end

-- === GUI (оставлен как есть) ===
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "YBAFarmGUI"
ScreenGui.Parent = game.CoreGui

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 300, 0, 200)
MainFrame.Position = UDim2.new(0, 20, 0, 20)
MainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
MainFrame.Parent = ScreenGui

local Title = Instance.new("TextLabel")
Title.Text = "YBA AUTO STORY v2.1"
Title.Size = UDim2.new(1, 0, 0, 30)
Title.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
Title.TextColor3 = Color3.fromRGB(255, 255, 0)
Title.Font = Enum.Font.GothamBold
Title.Parent = MainFrame

StatusLabel = Instance.new("TextLabel")
StatusLabel.Text = "Статус: Ожидание"
StatusLabel.Size = UDim2.new(0.9, 0, 0, 50)
StatusLabel.Position = UDim2.new(0.05, 0, 0.18, 0)
StatusLabel.BackgroundTransparency = 1
StatusLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
StatusLabel.Font = Enum.Font.Gotham
StatusLabel.Parent = MainFrame

-- === ОСНОВНОЙ ЦИКЛ (ТОЛЬКО ТВОЙ СЮЖЕТ) ===
function MainFarmLoop()
    while Config.AutoFarm do
        local QuestPanel = LocalPlayer.PlayerGui.HUD.Main.Frames.Quest.Quests

        if QuestPanel:FindFirstChild("Help Giorno by Defeating Security Guards") then
            if AcceptQuestFromNPC("Giorno") then
                task.wait(2)
                KillNPCContinuously("Security Guard", 5)
                AutoStoryDialogue()
            end

        elseif QuestPanel:FindFirstChild("Defeat Leaky Eye Luca") then
            -- ✅ КВЕСТ ДАЁТ GIOrno, НЕ Jotaro!
            if AcceptQuestFromNPC("Giorno") then
                task.wait(2)
                KillNPCContinuously("Leaky Eye Luca", 1)
                AutoStoryDialogue()
            end

        elseif QuestPanel:FindFirstChild("Defeat Bucciarati") then
            if AcceptQuestFromNPC("Giorno") then
                task.wait(2)
                KillNPCContinuously("Bucciarati", 1)
                AutoStoryDialogue()
            end

        elseif QuestPanel:FindFirstChild("Take down 3 vampires") then
            if AcceptQuestFromNPC("William Zeppeli [Lvl. 25+]") then
                task.wait(2)
                KillNPCContinuously("Vampire", 3)
                AutoStoryDialogue()
            end

        else
            -- Начало: поговорить с первым Giorno
            UpdateStatus("Ищу стартовый квест...")
            AcceptQuestFromNPC("Giorno")
            task.wait(5)
        end

        task.wait(1)
    end
end

-- === УПРАВЛЕНИЕ ===
game:GetService("UserInputService").InputBegan:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.F5 then
        Config.AutoFarm = not Config.AutoFarm
        UpdateStatus(Config.AutoFarm and "Запущено" or "Пауза")
        if Config.AutoFarm then task.spawn(MainFarmLoop) end
    elseif input.KeyCode == Enum.KeyCode.Delete then
        Config.AutoFarm = false
        ScreenGui:Destroy()
    end
end)

print("========================================")
print("YBA AUTO STORY v2.1 — ИСПРАВЛЕНО ДЛЯ СЮЖЕТА!")
print("F5: Старт | Delete: Выход")
print("========================================")

UpdateStatus("Готов. Нажмите F5.")
