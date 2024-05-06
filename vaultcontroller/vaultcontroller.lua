-- Vault Control System with Action Handling
local modemSide = "bottom"  -- The side where the modem is connected
local passcode = "123456"  -- Static 6-digit passcode
local vaultChannel = "vaultQuery"
local responseChannel = "vaultResponse"
local keypadID = 6  -- The ID of the terminal sending commands

-- Define redstone sides for mechanisms
local outerLockSide = "back"
local outerDoorSide = "right"
local innerDoorSide = "left"
local reverserGearSide = "front"
local alarmAndCloseSide = "top"

-- Control the state of the vault
local vaultState = "closed"  -- could also be "open" or "opening"

-- Function to emit a redstone pulse
function pulse(side, duration)
    redstone.setOutput(side, true)
    sleep(duration or 0.5)  -- Default pulse duration to 0.5 seconds
    redstone.setOutput(side, false)
end

-- Function to handle opening sequence
function openVault()
    if vaultState ~= "open" then
        redstone.setOutput(outerLockSide, true)
        sleep(2)
        redstone.setOutput(alarmAndCloseSide, true)
        sleep(2)
        pulse(innerDoorSide)  -- Pulse the inner door
        sleep(2)
        pulse(outerDoorSide)  -- Pulse the outer door
        sleep(2)
        redstone.setOutput(alarmAndCloseSide, false)
        vaultState = "open"
    end
end

-- Function to handle closing sequence
function closeVault()
    if vaultState ~= "closed" then
        redstone.setOutput(reverserGearSide, true)
        pulse(outerDoorSide)  -- Pulse the outer door
        sleep(2)
        pulse(innerDoorSide)  -- Pulse the inner door
        sleep(2)
        redstone.setOutput(alarmAndCloseSide, true)
        sleep(2)
        redstone.setOutput(outerLockSide, false)
        sleep(2)
        redstone.setOutput(reverserGearSide, false)
        vaultState = "closed"
    end
end

rednet.open(modemSide)
while true do
    local senderId, message, protocol = rednet.receive(vaultChannel)
    if senderId == keypadID then
        if message.action == "enter" and message.pin == passcode then
            rednet.send(senderId, "success", responseChannel)
            openVault()
        elseif message.action == "close" then
            rednet.send(senderId, "success", responseChannel)
            closeVault()
        else
            rednet.send(senderId, "failure", responseChannel)
        end
    end

    -- Check for redstone signal to close vault
    if redstone.getInput(alarmAndCloseSide) then
        closeVault()
    end
end
