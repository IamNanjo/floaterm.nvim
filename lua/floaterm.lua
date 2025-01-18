local M = {}

local state = {
    open = false,
    buf = nil,
    win = nil,
}

---@class config Plugin configuration
---@field auto_insert boolean Automatically enter insert mode. Default
---@field width_relative float Relative width of floating window. Default value is 0.8
---@field height_relative float Relative height of floating window. Default value is 0.8
---@field border "none"|"single"|"double"|"rounded"|"solid"|"shadow"|string[] Border type of floating window
---@
local config = {
    auto_insert = true,
    width_relative = 0.8,
    height_relative = 0.8,
    border = "rounded",
}

--- Set up plugin configuration
---@param opts config
M.setup = function(opts)
    for k, v in pairs(opts) do
        config[k] = v
    end
end

--- Create window configuration
---@return vim.api.keyset.win_config
local function create_window_configuration()
    local width = math.floor(vim.o.columns * config.width_relative)
    local height = math.floor(vim.o.lines * config.height_relative)

    return {
        relative = "editor",
        width = width,
        height = height,
        style = "minimal",
        border = config.border,
        col = math.floor((vim.o.columns - width) / 2),
        row = math.ceil((vim.o.lines - height) / 2),
        zindex = 10,
    }
end

local function buffer_is_terminal(buffer)
    return vim.bo[buffer].buftype == "terminal"
end

--- Creates a floating window and enters it automatically
---@param win_config vim.api.keyset.win_config?
local function open_floating_window(win_config)
    if not state.buf or not vim.api.nvim_buf_is_valid(state.buf) or not vim.api.nvim_buf_is_loaded(state.buf) then
        state.buf = vim.api.nvim_create_buf(false, true)

        if state.buf == 0 then
            error("Could not create floating terminal buffer")
        end
    end

    state.win = vim.api.nvim_open_win(state.buf, true, win_config or create_window_configuration())
    state.open = true

    if not buffer_is_terminal(state.buf) then
        vim.cmd.terminal()
    end

    vim.keymap.set({ "t" }, "<C-[>", "<c-\\><c-n>", { noremap = true, silent = true, buffer = state.buf })
    vim.keymap.set({ "n" }, "<C-[>", M.floaterm, { noremap = true, silent = true, buffer = state.buf })

    if config.auto_insert then
        vim.api.nvim_command("startinsert")
    end

    vim.bo[state.buf].buflisted = false
    vim.bo[state.buf].bufhidden = "hide"
end

M.floaterm = function()
    if state.buf and not vim.api.nvim_buf_is_loaded(state.buf) then
        state.buf = nil
        state.win = nil
        state.open = false
    end
    if state.win and not vim.api.nvim_win_is_valid(state.win) then
        state.win = nil
        state.open = false
    end

    if state.open and state.win then
        vim.api.nvim_win_hide(state.win)
    else
        open_floating_window()
    end
end

vim.api.nvim_create_user_command("Floaterm", M.floaterm, {})

vim.api.nvim_create_autocmd("VimResized", {
    callback = function()
        if not vim.api.nvim_win_is_valid(state.win) then
            return
        end

        vim.api.nvim_win_set_config(state.win, create_window_configuration())
    end,
})

return M
