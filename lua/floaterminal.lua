local M = {}

local state = {
    open = false,
    buf = nil,
    win = nil,
}

M.setup = function() end

--- Create window configuration
---@return vim.api.keyset.win_config
local function create_window_configuration()
    local width = math.floor(vim.o.columns * 0.8)
    local height = math.floor(vim.o.lines * 0.8)

    return {
        relative = "editor",
        width = width,
        height = height,
        style = "minimal",
        border = "rounded",
        col = math.floor((vim.o.columns - width) / 2),
        row = math.ceil((vim.o.lines - height) / 2),
        zindex = 10,
    }
end

local function buffer_is_terminal(buffer)
    return vim.bo[buffer].buftype == "terminal"
end

--- Creates a floating window and enters it automatically
---@param config vim.api.keyset.win_config?
local function open_floating_window(config)
    if not state.buf or not vim.api.nvim_buf_is_valid(state.buf) or not vim.api.nvim_buf_is_loaded(state.buf) then
        state.buf = vim.api.nvim_create_buf(false, true)

        if state.buf == 0 then
            error("Could not create floating terminal buffer")
        end
    end

    state.win = vim.api.nvim_open_win(state.buf, true, config or create_window_configuration())
    state.open = true

    if not buffer_is_terminal(state.buf) then
        vim.cmd.terminal()
    end

    vim.keymap.set({ "t" }, "<C-[>", "<c-\\><c-n>", { noremap = true, silent = true, buffer = state.buf })
    vim.keymap.set({ "t" }, "<C-[><C-[>", M.floaterminal, { noremap = true, silent = true, buffer = state.buf })
    vim.keymap.set({ "n" }, "<C-[>", M.floaterminal, { noremap = true, silent = true, buffer = state.buf })

    vim.api.nvim_command("startinsert")

    vim.bo[state.buf].buflisted = false
    vim.bo[state.buf].bufhidden = "hide"
end

M.floaterminal = function()
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

vim.api.nvim_create_user_command("Floaterminal", M.floaterminal, {})

vim.api.nvim_create_autocmd("VimResized", {
    callback = function()
        if not vim.api.nvim_win_is_valid(state.win) then
            return
        end

        vim.api.nvim_win_set_config(state.win, create_window_configuration())
    end,
})

return M
