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
---@field linesUsedForCachedDimensions string[]
---@field cachedDimensions Vec2
local UI = {}
UI.__index = UI

local function isValidWindow(win)
	if vim.api.nvim_win_get_config(win).relative ~= "" then
		return false
	end

	local buf = vim.api.nvim_win_get_buf(win)

	if not vim.api.nvim_buf_is_loaded(buf) then
		return false
	end

	if vim.bo[buf].buftype ~= "" then
		return false
	end

	if not vim.bo[buf].buflisted then
		return false
	end

	return true
end

local function getRightmostCol()
	local maxCol = 0
	local foundValidWindow = false

	for _, win in ipairs(vim.api.nvim_list_wins()) do
		if isValidWindow(win) then
			foundValidWindow = true
			local pos = vim.api.nvim_win_get_position(win)
			local width = vim.api.nvim_win_get_width(win)
			local rightEdge = pos[2] + width

			if rightEdge > maxCol then
				maxCol = rightEdge
			end
		end
	end

	if not foundValidWindow then
		maxCol = vim.o.columns
	end

	return maxCol
end

function UI:new(ctrl)
	---@type Workspaces.UI
	local obj = {
		bufId = nil,
		winId = nil,
		nsId = vim.api.nvim_create_namespace("workspaces-nvim"),
		ctrl = ctrl,
		lines = {},
		linesUsedForCachedDimensions = {},
		cachedDimensions = {x = 0, y = 0},
		width = 1,
	}

	setmetatable(obj, UI)

	return obj
end

function UI:init()
	self.bufId = vim.api.nvim_create_buf(false, true)
	for name, theme in pairs(THEMES) do
		vim.api.nvim_set_hl(0, theme, { fg = self.ctrl.config.colors[name] })
	end

	self.winId = vim.api.nvim_open_win(self.bufId, false, {
		relative = "editor",
		anchor = "NE",
		focusable = false,
		zindex = 21,
		width = 1,
		height = 1,
		row = 0,
		col = 0,
		hide = true
	})

	vim.api.nvim_set_option_value("winblend", 100, { win = self.winId })
	vim.api.nvim_set_option_value("number", false, { win = self.winId })
	vim.api.nvim_set_option_value("relativenumber", false, { win = self.winId })
	vim.api.nvim_set_option_value("signcolumn", "no", { win = self.winId })
	vim.api.nvim_set_option_value("foldcolumn", "0", { win = self.winId })
	vim.api.nvim_set_option_value("cursorline", false, { win = self.winId })

	vim.api.nvim_buf_set_lines(self.bufId, 0, -1, false, self.lines)

	self:updateLines()
	self:updatePos()
	self:updateDimensions()
	self:applyColors()

	self:setConfig({ hide = false })
end

---@param config vim.api.keyset.win_config
function UI:setConfig(config)
	local prevConfig = vim.api.nvim_win_get_config(self.winId)

	local newConfig = vim.tbl_extend("force", prevConfig, config)

	vim.api.nvim_win_set_config(self.winId, newConfig)
end

---@return Vec2
function UI:dimensions()
	if self.lines ~= self.linesUsedForCachedDimensions then
		local dimensions = {
			x = utils.max(self.lines),
			y = math.max(#self.lines, 1)
		}
		self.cachedDimensions = dimensions
		self.linesUsedForCachedDimensions = self.lines
	end

	return self.cachedDimensions
end

---@return Vec2
function UI:pos()
	local rightEdge = getRightmostCol()

	return {
		x = rightEdge - self.ctrl.config.offset.x,
		y = self.ctrl.config.offset.y,
	}
end

function UI:updatePos()
	local pos = self:pos()

	self:setConfig({
		col = pos.x,
		row = pos.y,
	})
end

function UI:updateDimensions()
	local dimensions = self:dimensions()

	self:setConfig({
		width = dimensions.x,
		height = dimensions.y
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

	local width = self:dimensions().x

	for index, line in ipairs(self.lines) do
		local padding = width - #line
		local newLine = string.rep(" ", padding) .. line
		self.lines[index] = newLine
	end

	vim.api.nvim_buf_set_lines(self.bufId, 0, -1, false, self.lines)
end

function UI:updateCurrentFileHighlight()
	self:applyColors()
end

function UI:applyColors()
	if self.winId == nil then return end

	vim.api.nvim_buf_clear_namespace(self.bufId, -1, 0, -1)
	local width = self:dimensions().x

	for index = 1, #self.ctrl.config.keys do
		local key = self.ctrl.config.keys:sub(index, index)
		local file = self.ctrl.workspace[key] or ""
		local currentPath = utils.sanitizePath(vim.fn.expand("%:p"))
		if file == currentPath then
			vim.api.nvim_buf_set_extmark(
				self.bufId,
				self.nsId,
				index - 1,
				0,
				{ hl_group = THEMES.currentFile, end_col = width }
			)
		end
	end
	for index, _ in ipairs(self.lines) do
		vim.api.nvim_buf_set_extmark(
			self.bufId,
			self.nsId,
			index - 1,
			width - 1,
			{ hl_group = THEMES.shortcut, end_col = width }
		)
	end
end

function UI:refresh()
	self:updateLines()
	self:updateDimensions()
	self:applyColors()
end

M.UI = UI

return M
