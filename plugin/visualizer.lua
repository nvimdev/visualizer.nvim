vim.api.nvim_create_user_command('VisualizerIncoming', function()
  require('visualizer').show_incoming()
end, { desc = 'Visualize incoming calls (who calls this function)' })

vim.api.nvim_create_user_command('VisualizerOutgoing', function()
  require('visualizer').show_outgoing()
end, { desc = 'Visualize outgoing calls (what this function calls)' })

vim.api.nvim_create_user_command('VisualizerFull', function()
  require('visualizer').show_full()
end, { desc = 'Visualize full call hierarchy (incoming + outgoing)' })
