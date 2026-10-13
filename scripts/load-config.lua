-- Runs a Lua config file and prints it as JSON for the QML side.
local function encode(v)
  local t = type(v)
  if t == "string" then
    return '"' .. (v:gsub('[%c"\\]', function(c)
      return string.format("\\u%04x", c:byte())
    end)) .. '"'
  elseif t == "number" or t == "boolean" then
    return tostring(v)
  elseif t == "table" then
    if #v > 0 then
      local out = {}
      for i, x in ipairs(v) do out[i] = encode(x) end
      return "[" .. table.concat(out, ",") .. "]"
    end
    local keys = {}
    for k in pairs(v) do keys[#keys + 1] = k end
    table.sort(keys)
    local out = {}
    for _, k in ipairs(keys) do
      out[#out + 1] = encode(tostring(k)) .. ":" .. encode(v[k])
    end
    return "{" .. table.concat(out, ",") .. "}"
  end
  return "null"
end

local ok, cfg = pcall(dofile, arg[1])
if not ok then
  io.stderr:write("sigil config error: " .. tostring(cfg) .. "\n")
  os.exit(1)
end
print(encode(cfg))
