local M = {}

---@generic T: table, K, V
---@param defaults T
---@param overrides T
---@return T
function M.merge_defaults(defaults, overrides)
  local result = {}
  for k, v in pairs(defaults) do
    result[k] = v
  end
  for k, v in pairs(overrides or {}) do
    result[k] = v
  end
  return result
end

return M
