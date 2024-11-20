-- This file is part of thesixthroc's Pirate Ship softmod, licensed under GPLv3 and stored at https://github.com/ComfyFactory/ComfyFactorio and https://github.com/danielmartin0/ComfyFactorio-Pirates.

-- local Utils = require 'maps.pirates.utils_local'
-- local Math = require 'maps.pirates.math'
local _inspect = require('utils.inspect').inspect
local GuiCommon = require('maps.pirates.gui.common')
local BuriedTreasure = require('maps.pirates.buried_treasure')
local Common = require('maps.pirates.common')
-- local Memory = require('maps.pirates.memory')
local Surfaces = require('maps.pirates.surfaces.surfaces')

local Public = {}

local window_name = 'treasure'

function Public.toggle_window(player)
	if player.gui.screen[window_name .. '_piratewindow'] then
		player.gui.screen[window_name .. '_piratewindow'].destroy()
		return
	end

	local flow, flow2, flow3
	flow = GuiCommon.new_window(player, window_name)
	flow.caption = { 'pirates.gui_treasure' }

	flow2 = GuiCommon.flow_add_section(flow, 'current_maps', { 'pirates.gui_treasure_discovered_maps' })

	flow3 = flow2.add({
		type = 'scroll-pane',
		name = 'treasure_scroll_pane',
		vertical_scroll_policy = 'auto',
		horizontal_scroll_policy = 'never',
	})
	flow3.style.maximal_height = 600

	local treasure_grid = flow3.add({
		type = 'table',
		name = 'treasure_grid',
		column_count = 2,
	})
	treasure_grid.style.horizontal_spacing = 8
	treasure_grid.style.vertical_spacing = 8

	GuiCommon.flow_add_close_button(flow, window_name .. '_piratebutton')
	return nil
end

function Public.full_update(player)
	if Public.regular_update then
		Public.regular_update(player)
	end
	if not player.gui.screen[window_name .. '_piratewindow'] then
		return
	end

	local destination = Common.current_destination()
	if destination.type ~= Surfaces.enum.ISLAND then
		player.gui.screen[window_name .. '_piratewindow'].destroy()
		return
	end

	local surface = game.surfaces[destination.surface_name]
	local treasure_maps = BuriedTreasure.get_picked_up_treasure_maps()

	local flow = player.gui.screen[window_name .. '_piratewindow']

	local flow1 = flow.current_maps.body.treasure_scroll_pane.treasure_grid

	for _, child in pairs(flow1.children) do
		if child.type == 'camera' then
			local matching_treasure_map = false
			for _, treasure_map in pairs(treasure_maps) do
				if child.name == treasure_map.id then
					matching_treasure_map = true
				end
			end
			if not matching_treasure_map then
				child.destroy()
			end
		end
	end

	for _, treasure_map in pairs(treasure_maps) do
		local flow2 = flow1[treasure_map.id]

		if not (flow2 and flow2.valid) then
			Common.ensure_chunks_at(surface, treasure_map.buried_treasure_position, 1)

			flow2 = flow1.add({
				type = 'camera',
				name = treasure_map.id,
				position = treasure_map.buried_treasure_position,
			})
			flow2.surface_index = surface.index
			flow2.zoom = 0.6
			flow2.style.minimal_height = 250
			flow2.style.minimal_width = 250
		end
	end

	flow.style.maximal_width = 1000
end

return Public
