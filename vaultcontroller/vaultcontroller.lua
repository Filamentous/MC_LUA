-- Vault Control System with Simplified Alarm and Control Logic
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
local closeInputSide = "top"  -- Used for closing the vault

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
        redstone.setOutput(reverserGearSide, false)
        redstone.setOutput(outerLockSide, true)  -- Disengage lock to start opening
        sleep(2)
        pulse(innerDoorSide)  -- Pulse the inner door
        sleep(2)
        pulse(outerDoorSide)  -- Pulse the outer door
        sleep(2)
        redstone.setOutput(outerLockSide, false)  -- Re-engage lock after opening
        redstone.setOutput(reverserGearSide, true)
        vaultState = "open"
    end
end

-- Function to handle closing sequence
function closeVault()
    if vaultState ~= "closed" then
        redstone.setOutput(reverserGearSide, true)
        redstone.setOutput(outerLockSide, true)  -- Disengage lock to start closing
        sleep(2)
        pulse(outerDoorSide)  -- Pulse the outer door
        sleep(2)
        pulse(innerDoorSide)  -- Pulse the inner door
        sleep(2)
        redstone.setOutput(outerLockSide, false)  -- Re-engage lock after closing
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

    -- Check for redstone signal to close vault from the top side
    if redstone.getInput(closeInputSide) then
        closeVault()
    end
end
