if game.PlaceId ~= 2809202155 then return end

local LocalPlayer = game:GetService("Players").LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local RemoteEvent = Character:WaitForChild("RemoteEvent")

local function SkipAllDialogue()
    local DialogueGui = LocalPlayer.PlayerGui:FindFirstChild("DialogueGui")
    if not DialogueGui then return end
    
    local Frame = DialogueGui:FindFirstChild("Frame")
    if not Frame then return end
    
    -- Instantly click the "Continue" button if it exists
    local ClickContinue = Frame:FindFirstChild("ClickContinue")
    if ClickContinue then
        fireclickdetector(ClickContinue:FindFirstChildOfClass("ClickDetector") or ClickContinue)
    end
    
    -- If there are multiple choice options, pick the first one instantly
    local Options = Frame:FindFirstChild("Options")
    if Options then
        for _, Option in pairs(Options:GetChildren()) do
            if Option:IsA("TextButton") or Option:FindFirstChildOfClass("TextButton") then
                local Button = Option:IsA("TextButton") and Option or Option:FindFirstChildOfClass("TextButton")
                if Button then
                    fireclickdetector(Button:FindFirstChildOfClass("ClickDetector") or Button)
                    break
                end
            end
        end
    end
end

-- Hook into the dialogue system
local __namecall
__namecall = hookmetamethod(game, "__namecall", function(self, ...)
    local method = getnamecallmethod()
    local args = {...}
    
    if method == "FireServer" and self == RemoteEvent and args[1] == "ProgressDialogue" then
        task.spawn(function()
            for i = 1, 10 do -- Try multiple times to ensure skip
                SkipAllDialogue()
                task.wait(0.01)
            end
        end)
    end
    
    return __namecall(self, ...)
end)

-- Also check for dialogue GUI appearing
LocalPlayer.PlayerGui.ChildAdded:Connect(function(child)
    if child.Name == "DialogueGui" then
        task.wait(0.05)
        for i = 1, 5 do
            SkipAllDialogue()
            task.wait(0.01)
        end
    end
end)

-- Force close any existing dialogue
if LocalPlayer.PlayerGui:FindFirstChild("DialogueGui") then
    LocalPlayer.PlayerGui.DialogueGui:Destroy()
end

print("Dialogue Skipper loaded - All dialogues will complete in milliseconds.")
