workshop = {}

function workshop.register_workshop(mod, name, def)
	if not workshop[mod] then
		workshop[mod] = {}
	end
	if not workshop[mod][name] then
		workshop[mod][name] = {}
	end

	workshop[mod][name].enough_supply = def.enough_supply
	workshop[mod][name].remove_supply = def.remove_supply
	workshop[mod][name].update_formspec_raw = def.update_formspec
	workshop[mod][name].update_inventory_raw = def.update_inventory


	workshop[mod][name].start = function(pos)
		local node = minetest.get_node(pos)
		if not (mod and name) then
			mod, name = minetest.get_node(pos).name:match("([^:]+):([^:]+)")
		end
		if node.name ~= mod .. ":" .. name or not workshop[mod][name] then
			return
		end

		local meta = minetest.get_meta(pos)
		if meta:get_string("working_on") ~= "" then
			return
		end

		local selection = meta:get_string("selection")
		if selection and selection ~= "" then
			if not workshop[mod][name].enough_supply(pos, selection) then
				return
			end
		else
			return
		end

		local inv = meta:get_inventory()
		if not inv:room_for_item("output", { name = selection, count = 1 }) then
			return
		end

		meta:set_string("working_on", selection)
		meta:set_int("progress", 0)

		workshop[mod][name].remove_supply(pos, selection)

		workshop[mod][name].step(pos)
	end

	workshop[mod][name].step = function(pos)
		local node = minetest.get_node(pos)
		if not (mod and name) then
			mod, name = minetest.get_node(pos).name:match("([^:]+):([^:]+)")
		end
		if node.name ~= mod .. ":" .. name or not workshop[mod][name] then
			return
		end

		local meta = minetest.get_meta(pos)
		if meta:get_string("working_on") ~= "" then
			return
		end

		local working_on = meta:get_string("working_on")

		local progress = meta:get_int("progress")
		progress = progress + 1

		local duration = 10
		if minetest.registered_items[working_on] and
				minetest.registered_items[working_on].workshop_duration then
			duration = minetest.registered_items[working_on].workshop_duration
		end

		if progress < duration then
			meta:set_int("progress", progress)
			minetest.after(0.2, workshop[mod][name].step, pos)
		else
			meta:set_int("progress", 0)
			progress = 0
			local inv = meta:get_inventory()
			inv:add_item("output", working_on)
			meta:set_string("working_on", "")
			workshop[mod][name].start(pos)
		end

		workshop[mod][name].update_formspec(pos)
	end

	workshop[mod][name].update_formpec = function(pos)
		if not (mod and name) then
			mod, name = minetest.get_node(pos).name:match("([^:]+):([^:]+)")
		end
		local node = minetest.get_node(pos)
		if node.name ~= mod .. ":" .. name or not workshop[mod][name] then
			return
		end
		workshop[mod][name].update_formspec_raw(pos)
	end

	workshop[mod][name].update_inventory = function(pos)
		if not (mod and name) then
			mod, name = minetest.get_node(pos).name:match("([^:]+):([^:]+)")
		end
		local node = minetest.get_node(pos)
		if node.name ~= mod .. ":" .. name or not workshop[mod][name] then
			return
		end
		workshop[mod][name].update_inventory_raw(pos)
		workshop[mod][name].update_formpec(pos)
		workshop[mod][name].start(pos)
	end

	workshop[mod][name].on_receive_fields = function(pos, formname, fields, sender)
		def.on_receive_fields(pos, formname, fields, sender)
	end

	workshop[mod][name].on_construct = function(pos)
		def.on_construct(pos)
		if not (mod and name) then
			mod, name = minetest.get_node(pos).name:match("([^:]+):([^:]+)")
		end
		workshop[mod][name].update_formpec(pos)
	end

	workshop[mod][name].allow_metadata_inventory_move = function(pos, from_list, from_index, to_list, to_index, count, player)
		return def.allow_metadata_inventory_move(pos, from_list, from_index, to_list, to_index, count, player)
	end

	workshop[mod][name].allow_metadata_inventory_put = function(pos, listname, index, stack, player)
		return def.allow_metadata_inventory_put(pos, listname, index, stack, player)
	end

	workshop[mod][name].allow_metadata_inventory_take = function(pos, listname, index, stack, player)
		return def.allow_metadata_inventory_take(pos, listname, index, stack, player)
	end

	workshop[mod][name].on_metadata_inventory_move = function(pos, from_list, from_index, to_list, to_index, count, player)
		if not (mod and name) then
			mod, name = minetest.get_node(pos).name:match("([^:]+):([^:]+)")
		end
		workshop[mod][name].update_inventory(pos)
	end

	workshop[mod][name].on_metadata_inventory_put = function(pos, listname, index, stack, player)
		if not (mod and name) then
			mod, name = minetest.get_node(pos).name:match("([^:]+):([^:]+)")
		end
		workshop[mod][name].update_inventory(pos)
	end

	workshop[mod][name].on_metadata_inventory_take = function(pos, listname, index, stack, player)
		if not (mod and name) then
			mod, name = minetest.get_node(pos).name:match("([^:]+):([^:]+)")
		end
		workshop[mod][name].update_inventory(pos)
	end

	workshop[mod][name].can_dig = function(pos, player)
		def.can_dig(pos, player)
	end

	local ndef = table.copy(def)
	ndef.on_receive_fields = workshop[mod][name].on_receive_fields
	ndef.on_construct = workshop[mod][name].on_construct
	ndef.allow_metadata_inventory_move = workshop[mod][name].allow_metadata_inventory_move
	ndef.allow_metadata_inventory_put = workshop[mod][name].allow_metadata_inventory_put
	ndef.allow_metadata_inventory_take = workshop[mod][name].allow_metadata_inventory_take
	ndef.on_metadata_inventory_move = workshop[mod][name].on_metadata_inventory_move
	ndef.on_metadata_inventory_put = workshop[mod][name].on_metadata_inventory_put
	ndef.on_metadata_inventory_take = workshop[mod][name].on_metadata_inventory_take
	ndef.can_dig = workshop[mod][name].can_dig

	minetest.register_node(mod .. ":" .. name, ndef)
end