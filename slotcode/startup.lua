-- Peripheral setup
local monitor = peripheral.wrap("top")  -- Adjust based on your setup for a 2x2 monitor
local speaker = peripheral.find("speaker")  -- Automatically finds a speaker
local modem = peripheral.wrap("back")  -- Modem on the back for rednet

-- Define symbols, win conditions, and costs
local symbols = {"Cherry", "Bell", "BAR", "7", "Diamond"}
local betAmount = 2
local jackpot = 64
local databaseID = 5  -- The ID of your central database

-- Setup rednet
rednet.open("back")

-- Display instructions and get input from screen
function getPlayerIDFromScreen()
    monitor.clear()
    monitor.setCursorPos(1, 1)
    monitor.write("Please enter your Player ID:")
    monitor.setCursorPos(1, 2)
    local event, side, x, y = os.pullEvent("monitor_touch")  -- Wait for touch input
    monitor.setCursorPos(1, 3)
    local input = read()  -- Assumes a keyboard is connected for input
    return tonumber(input)
end

-- Check player balance
function checkBalance(playerID)
    rednet.send(databaseID, {type = "checkBalance", playerID = playerID}, "databaseQuery")
    local id, message = rednet.receive("databaseResponse")
    return message.balance
end

-- Update player balance
function updateBalance(playerID, amount)
    rednet.send(databaseID, {type = "updateBalance", playerID = playerID, amount = amount}, "databaseQuery")
end

-- Function to simulate the spinning of the slot reels
function spinReels()
    local results = {}
    for i = 1, 3 do
        table.insert(results, symbols[math.random(#symbols)])
    end
    return results
end

-- Calculate winnings based on the results
function calculateWinnings(results)
    if results[1] == results[2] and results[2] == results[3] then
        return results[1] == "7" and jackpot or jackpot / 4
    end
    return 0
end

-- Play sound based on result
function playResultSound(winnings)
    if winnings > 0 then
        speaker.playSound("file:///win.mp3", 0.3)  -- Play win sound at 30% volume from local file
    else
        speaker.playSound("file:///loss.mp3", 0.3)  -- Play loss sound at 30% volume from local file
    end
end

-- Display results and information on the monitor
function displayInfo(info, row)
    monitor.setCursorPos(1, row)
    monitor.clearLine()
    monitor.write(info)
end

-- Main function to handle slot machine logic
function playSlotMachine(playerID)
    local balance = checkBalance(playerID)
    displayInfo("Balance: " .. balance, 1)

    if balance < betAmount then
        displayInfo("Insufficient funds to play.", 2)
        return
    end

    updateBalance(playerID, -betAmount)  -- Deduct the bet amount

    displayInfo("Spinning... Press any key to stop!", 3)
    os.pullEvent("key")  -- Wait for user to press a key to stop spinning
    local results = spinReels()
    local winnings = calculateWinnings(results)

    updateBalance(playerID, winnings)  -- Update the balance with winnings
    balance = checkBalance(playerID)  -- Get updated balance

    displayInfo("Results: " .. table.concat(results, " | "), 4)
    displayInfo("Winnings: " .. winnings, 5)
    displayInfo("New Balance: " .. balance, 6)

    playResultSound(winnings)
end

function main()
    monitor.setTextScale(0.5)  -- Adjust text scale for better visibility on a 2x2 monitor
    local playerID = getPlayerIDFromScreen()  -- Get player ID from screen input
    if playerID then
        playSlotMachine(playerID)
    else
        monitor.clear()
        monitor.setCursorPos(1, 1)
        monitor.write("Invalid Player ID entered.")
    end
end

-- Start the slot machine
main()