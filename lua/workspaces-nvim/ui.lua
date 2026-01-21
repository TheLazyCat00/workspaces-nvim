local utils = require "workspaces-nvim.utils"

local THEMES = {
	shortcut = "WorkspacesShortcut",
	currentFile = "WorkspacesCurrentFile",
}

local M = {}

---@class Workspaces.UI
---@field winId number?
---@field bufId number?
---@field nsId number
---@field ctrl Workspaces.Ctrl
---@field lines string[]
---@field width integer
---@field height integer
local UI = {}
UI.__index = UI

function UI:new(ctrl)
	local obj = {
		bufId = vim.api.nvim_create_buf(false, true),
		winId = nil,
		nsId = vim.api.nvim_create_namespace("workspaces-nvim"),
		ctrl = ctrl,
		lines = {},
		width = 1,
	}

	setmetatable(obj, UI)

	return obj
end

function UI:init()
	for name, theme in pairs(THEMES) do
		vim.api.nvim_set_hl(self.nsId, theme, { fg = self.ctrl.config.colors[name] })
	end
	self:updateLines()
	local dims = self:dimensions()
	local pos = self:pos()

	self.winId = vim.api.nvim_open_win(self.bufId, false, {
		relative = "editor",
		width = dims.x,
		height = dims.y,
		col = pos.x,
		row = pos.y,
		focusable = false,
		zindex = 21,
	})
	vim.api.nvim_set_option_value("winblend", 100, { win = self.winId })
	vim.api.nvim_set_option_value("number", false, { win = self.winId })
	vim.api.nvim_set_option_value("relativenumber", false, { win = self.winId })
	vim.api.nvim_set_option_value("signcolumn", "no", { win = self.winId })
	vim.api.nvim_set_option_value("foldcolumn", "0", { win = self.winId })
	vim.api.nvim_set_option_value("cursorline", false, { win = self.winId })

	vim.api.nvim_buf_set_lines(self.bufId, 0, -1, false, self.lines)
	self:applyColors()
end

---@return Vec2
function UI:dimensions()
	return {
		x = self.width,
		y = math.max(#self.lines, 1)
	}
end

---@return Vec2
function UI:pos()
	return {
		x = vim.o.columns - self.width,
		y = 0,
	}
end

function UI:updateDims()
	local dims = self:dimensions()
	local pos = self:pos()

	vim.api.nvim_win_set_buf(self.winId, self.bufId)
	vim.api.nvim_win_set_config(self.winId, {
		relative = "editor",
		width = dims.x,
		height = dims.y,
		col = pos.x,
		row = pos.y,
	})
end

function UI:updateLines()
	self.lines = {}
	for i = 1, #self.ctrl.config.keys do
		local key = self.ctrl.config.keys:sub(i, i)
		local file = self.ctrl.workspace[key] or ""
		file = vim.fn.fnamemodify(file, ":t")
		table.insert(self.lines, file .. " " .. key)
	end

	self.width = utils.max(self.lines)

	for index, line in ipairs(self.lines) do
		local padding = self.width - #line
		local newLine = string.rep(" ", padding) .. line
		self.lines[index] = newLine
	end
end

function UI:applyColors()
	vim.api.nvim_buf_clear_namespace(self.bufId, -1, 0, -1)
	for index = 1, #self.ctrl.config.keys do
		local key = self.ctrl.config.keys:sub(index, index)
		local file = self.ctrl.workspace[key] or ""
		local currentPath = utils.sanitizePath(vim.fn.expand("%:p"))
		if file == currentPath then
			vim.api.nvim_buf_set_extmark(self.bufId, self.nsId, index - 1, 0, { hl_group = THEMES.currentFile, end_col = self.width })
		end
	end
	for index, line in ipairs(self.lines) do
		vim.api.nvim_buf_set_extmark(self.bufId, self.nsId, index - 1, self.width - 1, { hl_group = THEMES.shortcut, end_col = self.width })
	end
end

function UI:refresh()
	if self.winId == nil then
		return
	end
	self:updateLines()
	self:updateDims()

	vim.api.nvim_buf_set_lines(self.bufId, 0, -1, false, self.lines)
	self:applyColors()
end

M.UI = UI

return M
