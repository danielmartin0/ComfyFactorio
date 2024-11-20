local ICW = require 'maps.mountain_fortress_v3.icw.table'
local ICW_Func = require 'maps.mountain_fortress_v3.icw.functions'
local Discord = require 'utils.discord_handler'
local Commands = require 'utils.commands'
local mapkeeper = '[color=blue]Mapkeeper:[/color]'

Commands.new('icw_reconnect_train', 'Usable only for admins - reconnects all trains!')
	:require_admin()
	:require_validation()
	:callback(
		function (player)
			local icw = ICW.get()
			local suc = ICW_Func.reconstruct_all_trains(icw)
			Discord.send_notification_raw(ICW.discord_name, player.name .. ' is reconnecting all trains via icw module.')
			if suc then
				player.print(mapkeeper .. 'All trains have been reconnected!')
			else
				player.print(mapkeeper .. 'Failed to reconnect all trains!')
			end
			return true
		end
	)
