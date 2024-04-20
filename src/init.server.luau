--[[
    Oneko
    Cat follow cursor
    -kerrmeet 2024
--]]

local runService = game:GetService("RunService")
local userInputService = game:GetService("UserInputService")

if runService:IsRunMode() then return end

local settings = {
    Scale = 2;
    Speed = 10;
    Variant = "default";
    Custom = "";
}
for k, v in settings do
    settings[k] = plugin:GetSetting(k) or v
end
_G.Oneko = settings

local atlas = require(script:WaitForChild("Atlas"))
local nekos = require(script:WaitForChild("Neko"))

local nekoSpeed = 10
local nekoPosition = userInputService:GetMouseLocation()

local forceSleep = false

local gui = Instance.new("ScreenGui")
gui.Parent = game:GetService("CoreGui")

local image = Instance.new("ImageButton")
image.ImageRectSize = Vector2.new(32, 32)
image.ResampleMode = Enum.ResamplerMode.Pixelated
image.BackgroundTransparency = 1
image.AnchorPoint = Vector2.new(0.5, 0.5)
image.Parent = gui

local function toggleSleep()
    forceSleep = not forceSleep
end
image.MouseButton1Click:Connect(toggleSleep)

local function setSprite(animation, frame)
    local frames = atlas[animation]
    local offset = frames[(frame % #frames) + 1]
    image.ImageRectOffset = offset * 32
end

local idleAnimation = ""
local idleAnimationFrame = 0
local function resetIdleAnimation()
    idleAnimation = ""
    idleAnimationFrame = 0
end

local idleTime = 0
local function idle()
    idleTime += 1

    if idleTime > 10 and math.random(0, 100) == 0 and idleAnimation == "" then
        local availableIdleAnimations = {
            "sleeping", "scratchSelf",
            "scratchWallN", "scratchWallS", "scratchWallW", "scratchWallE"
        }
        idleAnimation = availableIdleAnimations[math.random(1, #availableIdleAnimations)]
    end

    if forceSleep then
        idleAnimation = "sleeping"
    end

    if idleAnimation == "sleeping" then
        if idleAnimationFrame < 8 then
            setSprite("tired", 0)
        else
            setSprite("sleeping", math.floor(idleAnimationFrame / 4))
        end
        if idleAnimationFrame > 192 and not forceSleep then
            resetIdleAnimation()
        end
    elseif idleAnimation:match("scratch") then
        setSprite(idleAnimation, idleAnimationFrame)
        if idleAnimationFrame > 9 then
            resetIdleAnimation()
        end
    else
        setSprite("idle", 0)
        return
    end
    idleAnimationFrame += 1
end
local frameCount = 0
local function frame()
    frameCount += 1

    local forceSleepPosition = workspace.CurrentCamera.ViewportSize - (Vector2.new(48, 13) * settings.Scale)
    local mousePosition = userInputService:GetMouseLocation()
    if forceSleep then
        mousePosition = forceSleepPosition
    end

    local difference = mousePosition - nekoPosition
    local distance = difference.Magnitude

    if forceSleep and distance < nekoSpeed then
        nekoPosition = forceSleepPosition
        idle()
        return
    end

    if (distance < nekoSpeed or distance < 48 * settings.Scale) and not forceSleep then
        idle()
        return
    end

    idleAnimation = ""
    idleAnimationFrame = 0

    if idleTime > 1 then
        setSprite("alert", 0)
        idleTime = math.min(idleTime - 1, 7)
        return
    end

    local direction = if difference.Y / distance > 0.5 then "S" else ""
    direction ..= if difference.Y / distance < -0.5 then "N" else ""
    direction ..= if difference.X / distance > 0.5 then "E" else ""
    direction ..= if difference.X / distance < -0.5 then "W" else ""
    setSprite(direction, frameCount)

    nekoPosition += difference.Unit * nekoSpeed
end

local totalDeltaTime = 0
local function renderLoop(dt:number)
    local nekoSize = Vector2.new(32, 32) * settings.Scale
    image.Size = UDim2.fromOffset(nekoSize.X, nekoSize.Y)

    nekoSpeed = settings.Speed * settings.Scale
    image.Position = UDim2.fromOffset(nekoPosition.X, nekoPosition.Y)

    nekos["custom"] = settings.Custom
    image.Image = nekos[settings.Variant]

    totalDeltaTime += dt
    while totalDeltaTime >= 1/10 do
        frame()
        totalDeltaTime -= 1/10
    end
end
runService:BindToRenderStep("oneko", Enum.RenderPriority.Input.Value + 1, renderLoop)

plugin.Unloading:Connect(function()
    runService:UnbindFromRenderStep("oneko")
    gui:Destroy()
    for k, v in settings do
        plugin:SetSetting(k, v)
    end
end)