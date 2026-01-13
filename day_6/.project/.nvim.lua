vim.opt.makeprg = "build.bat"

vim.opt.errorformat = "%f(%l): %m"

vim.keymap.set("n", "<F5>",
    function()
	vim.cmd("!build.bat -d")
    end,
    { desc = "Build project debug" }
)

local cwd = vim.fn.getcwd()
local last_slash_i = string.find(cwd, "/[^/]*$")
if last_slash_i == nil then
    last_slash_i = string.find(cwd, "\\[^\\]*$")
end
local target_name = string.sub(cwd, last_slash_i - string.len(cwd))

vim.keymap.set("n", "<F6>",
    function()
	vim.cmd("!build.bat -d")
	vim.cmd("!del \"bin\\debug\\*.rdi\"")
	vim.cmd("!raddbg --auto_step bin/debug/" .. target_name .. ".exe")
    end,
    { desc = "Build & Debug project" }
)

vim.keymap.set("n", "<F7>",
    function()
	vim.cmd("!build.bat")
    end,
    { desc = "Build project release" }
)

vim.keymap.set("n", "<F8>",
    function()
	vim.cmd("!build.bat")
	vim.cmd("!start cmd /c \"bin\\release\\" .. target_name .. ".exe\"")
    end,
    { desc = "Build & Run project release" }
)

vim.notify("Project config loaded successfully.", vim.log.levels.INFO)
