local M = {}

---@param path Path
---@return table<Path, Workspace>
function M.read(path)
	local jsonString = vim.fn.readfile(path)
	return vim.json.decode(jsonString[1])
end

---@param path Path
---@param data table<Path, Workspace>
function M.write(path, data)
	local jsonString = vim.json.encode(data)
	vim.fn.writefile({ jsonString }, path)
end

---@param path Path
---@return Path
function M.sanitizePath(path)
	path = path:gsub("\\", "/")
	return path
end

---@return Path
function M.getcwd()
	local cwd = vim.fn.getcwd()
	return M.sanitizePath(cwd)
end

---@param msg string
function M.alert(msg)
	vim.notify(msg, vim.log.levels.WARN)
end


---@param list string[]
function M.max(list)
    local longest = ""
    for _, s in pairs(list) do
        if #s > #longest then
            longest = s
        end
    end
    return #longest
end

return M
