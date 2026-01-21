local M = {}

---@param value any
---@return boolean
local function is_table(value)
  return type(value) == "table" and not vim.islist(value)
end

---@generic T: table, K, V
---@param defaults T
---@param overrides T
---@return T
function M.merge_defaults(defaults, overrides)
  if overrides == nil then
    return defaults
  end

  local result = {}

  for k, v in pairs(defaults) do
    if is_table(v) and is_table(overrides[k]) then
      result[k] = M.merge_defaults(v, overrides[k])
    elseif overrides[k] ~= nil then
      result[k] = overrides[k]
    else
      result[k] = v
    end
  end

  -- Add keys from overrides that don't exist in defaults
  for k, v in pairs(overrides) do
    if result[k] == nil then
      result[k] = v
    end
  end

  return result
end

return M
