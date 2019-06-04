local upgrade_planner_converter = {}

-- character table string
local b = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"

-- encoding
upgrade_planner_converter.enc = function(data)
  return ((data:gsub(
    ".",
    function(x)
      local r, b = "", x:byte()
      for i = 8, 1, -1 do
        r = r .. (b % 2 ^ i - b % 2 ^ (i - 1) > 0 and "1" or "0")
      end
      return r
    end
  ) .. "0000"):gsub(
    "%d%d%d?%d?%d?%d?",
    function(x)
      if (#x < 6) then
        return ""
      end
      local c = 0
      for i = 1, 6 do
        c = c + (x:sub(i, i) == "1" and 2 ^ (6 - i) or 0)
      end
      return b:sub(c + 1, c + 1)
    end
  ) .. ({"", "==", "="})[#data % 3 + 1])
end

-- decoding
upgrade_planner_converter.dec = function(data)
  data = string.gsub(data, "[^" .. b .. "=]", "")
  return (data:gsub(
    ".",
    function(x)
      if (x == "=") then
        return ""
      end
      local r, f = "", (b:find(x) - 1)
      for i = 6, 1, -1 do
        r = r .. (f % 2 ^ i - f % 2 ^ (i - 1) > 0 and "1" or "0")
      end
      return r
    end
  ):gsub(
    "%d%d%d?%d?%d?%d?%d?%d?",
    function(x)
      if (#x ~= 8) then
        return ""
      end
      local c = 0
      for i = 1, 8 do
        c = c + (x:sub(i, i) == "1" and 2 ^ (8 - i) or 0)
      end
      return string.char(c)
    end
  ))
end

upgrade_planner_converter.to_upgrade_planner = function(stack, config, player)
  local hashmap = get_hashmap(config)
  stack.set_stack {name = "upgrade-planner"}
  local idx = 1
  local error = false
  for item, configmap in pairs(hashmap) do
    local from_entity = nil
    if configmap.item_from ~= nil then
      from_entity = game.entity_prototypes[configmap.item_from]
      stack.set_mapper(idx, "from", {type = "entity", name = from_entity.name})
    end
    if configmap.item_to ~= nil then
      local to_entity = game.entity_prototypes[configmap.item_to]
      if from_entity.fast_replaceable_group == to_entity.fast_replaceable_group then
        stack.set_mapper(idx, "to", {type = "entity", name = to_entity.name})
      else
        player.print({"upgrade-planner.partial-upgrade-planner-export", from_entity.localised_name, to_entity.localised_name})
        stack.set_mapper(idx, "from", nil)
      end
    end
    idx = idx + 1
  end
end

upgrade_planner_converter.from_upgrade_planner = function(stack)
  local config = {}
  for i = 1, MAX_STORAGE_SIZE, 1 do
    local from = stack.get_mapper(i, "from").name or ""
    local to = stack.get_mapper(i, "to").name or ""

    config[i] = {from = from, to = to}
  end

  return config
end

return upgrade_planner_converter