if vim.g.load_visualizer then
  return
end

vim.g.load_visualizer = true

vim.api.nvim_create_user_command('Visualizer', function(args)
  local f = require('visualizer')[args.args]
  if f then
    f()
  end
end, {
  nargs = 1,
  complete = function()
    return vim.tbl_keys(require('visualizer'))
  end,
})
