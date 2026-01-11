vim.opt.makeprg = "build.bat"

vim.opt.errorformat = "%f(%l): %m"

vim.keymap.set("n", "<F5>",
    function()
	vim.cmd("!build.bat")
    end,
    { desc = "Build project" }
)

local cwd = vim.fn.getcwd()
local last_slash_i = string.find(cwd, "/[^/]*$")
if last_slash_i == nil then
    last_slash_i = string.find(cwd, "\\[^\\]*$")
end
local target_name = string.sub(cwd, last_slash_i - string.len(cwd))

vim.keymap.set("n", "<F6>",
    function()
	vim.cmd("!build.bat")
	vim.cmd("!del \"bin\\debug\\*.rdi\"")
	vim.cmd("!raddbg bin/debug/" .. target_name .. ".exe")
    end,
    { desc = "Build & Debug project" }
)

vim.keymap.set("n", "<F7>",
    function()
	vim.cmd("!build.bat")
	vim.cmd("!start cmd /c \"bin\\debug\\" .. target_name .. ".exe\"")
    end,
    { desc = "Build & Run project" }
)

vim.notify("Project config loaded successfully.", vim.log.levels.INFO)
