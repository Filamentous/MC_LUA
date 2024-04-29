-- Database storage setup
local balances = {}
local authorizedIDs = {6, 7}  -- IDs of authorized machines, including slot machine

-- Load existing data
if fs.exists("balances.txt") then
    local file = fs.open("balances.txt", "r")
    balances = textutils.unserialize(file.readAll())
    file.close()
end

function table.contains(table, element)
    for _, value in pairs(table) do
        if value == element then
            return true
        end
    end
    return false
end

-- Function to get the balance of a card
function getBalance(cardNumber)
    if balances[cardNumber] then
        print("Found: " .. cardNumber)
        return true, balances[cardNumber]
    else
        print("Did not find: " .. cardNumber)
        return false, "Card number does not exist."
    end
end

-- Function to update balance and write to file
function updateBalance(playerID, amount)
    balances[playerID] = (balances[playerID] or 0) + amount
    print("Updated balance for player ID " .. playerID .. ": +" .. amount)
    writeToFile()
end

-- Function to handle new card/account creation
function createNewCard(cardNumber)
    if balances[cardNumber] then
        print("Attempt to create a new card failed; card number already exists: " .. cardNumber)
        return false, "Account already exists."
    else
        balances[cardNumber] = 0
        print("New card created with card number: " .. cardNumber)
        writeToFile()
        return true, "New account created."
    end
end

-- General function to write changes to file
function writeToFile()
    local file = fs.open("balances.txt", "w")
    file.write(textutils.serialize(balances))
    file.close()
    print("Balance data written to file.")
end

-- Function to check if a card number exists
function checkCardExists(cardNumber)
    local exists = balances[cardNumber] ~= nil
    print("Check if card exists (" .. cardNumber .. "): " .. tostring(exists))
    return exists
end

-- Server loop to handle requests
function main()
    rednet.open("back")
    print("Database server started, waiting for requests...")
    while true do
        local senderId, message, protocol = rednet.receive("databaseQuery")
        print("Received request from ID " .. senderId)
        if table.contains(authorizedIDs, senderId) then  -- Check if the sender is authorized
            if message.type == "updateBalance" and message.playerID and message.amount then
                updateBalance(message.playerID, message.amount)
            elseif message.type == "createNewCard" and message.cardNumber then
                local success, response = createNewCard(message.cardNumber)
                rednet.send(senderId, {success = success, response = response}, "databaseResponse")
            elseif message.type == "checkCard" and message.cardNumber then
                local exists = checkCardExists(message.cardNumber)
                rednet.send(senderId, {exists = exists}, "databaseResponse")
            elseif message.type == "getBalance" and message.cardNumber then
                local success, balance = getBalance(message.cardNumber)
                rednet.send(senderId, {success = success, balance = balance}, "databaseResponse")
            end
        else
            print("Unauthorized access attempt from ID " .. senderId)
        end
    end
end

-- Run the main function
main()
