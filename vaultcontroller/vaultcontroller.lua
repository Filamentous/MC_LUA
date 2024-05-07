-- Vault Control System with Command Logging and Message Reception Feedback
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
        print("Opening vault...")
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
        print("Vault is now open.")
    end
end

-- Function to handle closing sequence
function closeVault()
    if vaultState ~= "closed" then
        print("Closing vault...")
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
        print("Vault is now closed.")
    end
end

rednet.open(modemSide)
while true do
    local senderId, message, protocol = rednet.receive(vaultChannel)
    print("Received message from ID " .. senderId .. ": " .. textutils.serialize(message))
    if senderId == keypadID then
        if message.action == "close" then
            print("Processing close command...")
            rednet.send(senderId, "success", responseChannel)
            closeVault()
        elseif message.action == "enter" and message.pin == passcode then
            print("Processing enter command...")
            rednet.send(senderId, "success", responseChannel)
            openVault()
        else
            print("Invalid command or incorrect passcode.")
            rednet.send(senderId, "failure", responseChannel)
        end
    end

    -- Check for redstone signal to close vault from the top side
    if redstone.getInput(closeInputSide) and vaultState ~= "open" then
        print("Redstone signal detected for closing.")
        closeVault()
    end
end
