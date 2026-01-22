local utils = require("workspaces-nvim.utils")
local config = require("workspaces-nvim.defaults")
local ui = require("workspaces-nvim.ui")

local M = {}

---@class Workspaces.Ctrl
---@field config Config
---@field dataPath Path
---@field workspace Workspace
---@field ui Workspaces.UI
local Controller = {}
Controller.__index = Controller

---@param dataPath Path
function Controller:new(dataPath, config)
	if vim.uv.fs_stat(dataPath) == nil then
		vim.fn.mkdir(vim.fn.fnamemodify(dataPath, ":h"), "p")
		utils.write(dataPath, vim.empty_dict())
	end

	---@type Workspaces.Ctrl
	local obj
	obj = {
		config = config,
		dataPath = dataPath,
		workspace = {},
		ui = nil
	} setmetatable(obj, Controller)

	obj.ui = ui.UI:new(obj)
	obj:setupEvents()
	obj:setupKeymaps()

	return obj
end

local function refreshWrap(ctrlFunc, uiFunc)
	---@param ctrl Workspaces.Ctrl
	local callback = function(ctrl)
		if ctrlFunc ~= nil then
			ctrlFunc(ctrl)
		end
		if uiFunc ~= nil then
			uiFunc(ctrl.ui)
		end
	end
	return callback
end

function Controller:setupEvents()
	local events = {
		VimLeavePre = Controller.saveWorkspace,
		DirChangedPre = Controller.saveWorkspace,
		DirChanged = refreshWrap(Controller.openWorkspace, ui.UI.refresh),
		UIEnter = refreshWrap(Controller.openWorkspace, ui.UI.init),
		BufEnter = refreshWrap(nil, ui.UI.applyColors),
		WinClosed = function (ctrl)
			vim.schedule(function ()
				ui.UI.refresh(ctrl.ui)
				ui.UI.applyColors(ctrl.ui)
			end)
		end,
		WinNew = function (ctrl)
			ui.UI.refresh(ctrl.ui)
			ui.UI.applyColors(ctrl.ui)
		end,
	}
	for event, callback in pairs(events) do
		vim.api.nvim_create_autocmd(event, {
			callback = function ()
				callback(self)
			end
		})
	end
end

function Controller:init()
	self:openWorkspace()
	self.ui:init()
end

function Controller:setupKeymaps()
	for i = 1, #self.config.keys do
		local key = self.config.keys:sub(i, i)
		local selectKey = self.config.selectLeaderKey .. key
		vim.keymap.set("n", selectKey, function ()
			self:editTab(key)
		end, { desc = "Switch to " .. key })

		local pinKey = self.config.pinLeaderKey .. key
		vim.keymap.set("n", pinKey, function ()
			self:pinToTab(key)
		end, { desc = "Pin file to " .. key })
	end
end

---@param path Path
---@return Workspace
function Controller:getWorkspace(path)
	local workspaces = utils.read(self.dataPath)
	return workspaces[path] or {}
end

---@param path Path
---@param workspace Workspace
function Controller:setWorkspace(path, workspace)
	local workspaces = utils.read(self.dataPath)
	workspaces[path] = workspace
	utils.write(self.dataPath, workspaces)
end

function Controller:saveWorkspace()
	local cwd = utils.getcwd()
	self:setWorkspace(cwd, self.workspace)
end

function Controller:openWorkspace()
	local cwd = utils.getcwd()
	self.workspace = self:getWorkspace(cwd)
end

---@param tab Tab
function Controller:editTab(tab)
	local path = self.workspace[tab]
	if path == nil then
		utils.alert("Tab " .. tab .. " has no file")
		return
	end

	if vim.uv.fs_stat(path) == nil then
		utils.alert("File of tab " .. tab .. " doesn't exist")
		return
	end

	vim.cmd("edit " .. path)
end

---@param tab Tab
function Controller:pinToTab(tab)
	local currentPath = utils.sanitizePath(vim.fn.expand("%:p"))
	self.workspace[tab] = currentPath
end

function M.setup(opts)
	config = vim.tbl_extend("force", config, opts)
	local dataPath = vim.fn.stdpath("data") .. "/workspaces-nvim/workspaces.json"
	Controller:new(dataPath, config)
end

return M
