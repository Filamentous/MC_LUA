local json = {}

function json.encode(table)
    -- Simple function to encode a table to JSON
    -- Implement encoding logic based on your needs or use an existing library
    return textutils.serialize(table)
end

function json.decode(jsonString)
    -- Simple function to decode JSON to a table
    -- Implement decoding logic based on your needs or use an existing library
    return textutils.unserialize(jsonString)
end

return json
