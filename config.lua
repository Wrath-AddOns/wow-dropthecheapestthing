local core = LibStub("AceAddon-3.0"):GetAddon("DropTheCheapestThing")
local module = core:NewModule("Config", "AceConsole-3.0")
local db

local function removable_item(itemid)
	return {
		type = "execute",
		name = GetItemInfo(itemid) or itemid,
		arg = itemid,
	}
end

local function item_list_group(name, order, description, db_table)
	local group = {
		type = "group",
		name = name,
		order = order,
		args = {},
	}
	group.args.about = {
		type = "description",
		name = description,
		order = 0,
	}
	group.args.add = {
		type = "input",
		name = "Add",
		desc = "Add an item, either by pasting the item link, dragging the item into the field, or entering the itemid.",
		get = function(info) return '' end,
		set = function(info, v)
			local itemid = core.link_to_id(v) or tonumber(v)
			db_table[itemid] = true
			group.args.remove.args[tostring(itemid)] = removable_item(itemid)
			core:BAG_UPDATE()
		end,
		validate = function(info, v)
			if v:match("^%d+$") or v:match("item:%d+") then
				return true
			end
		end,
		order = 10,
	}
	group.args.remove = {
		type = "group",
		inline = true,
		name = "Remove",
		order = 20,
		func = function(info)
			db_table[info.arg] = nil
			group.args.remove.args[info[#info]] = nil
			core:BAG_UPDATE()
		end,
		args = {
			about = {
				type = "description",
				name = "Remove an item.",
				order = 0,
			},
		},
	}
	for itemid in pairs(db_table) do
		group.args.remove.args[tostring(itemid)] = removable_item(itemid)
	end
	return group
end

function module:OnInitialize()
	db = core.db

	local options = {
		type = "group",
		name = "DropTheCheapestThing",
		get = function(info) return db.profile[info[#info]] end,
		set = function(info, v) db.profile[info[#info]] = v; core:BAG_UPDATE() end,
		args = {
			general = {
				type = "group",
				name = "General",
				order = 10,
				args = {
					threshold = {
						type = "range",
						name = "Quality Threshold",
						desc = "Choose the maximum quality of item that will be considered for dropping. 0 is grey, 1 is white, 2 is green, etc.",
						min = 0, max = 7, step = 1,
						order = 10,
					},
				},
			},
			always = item_list_group("Always Consider", 20, "Items listed here will *always* be considered junk and sold/dropped, regardless of the quality threshold that has been chosen. Be careful with this -- you'll never be prompted about it, and it will have no qualms about dropping things that could be auctioned for 5000g.", db.profile.always_consider),
			never = item_list_group("Never Consider", 30, "Items listed here will *never* be considered junk and sold/dropped, regardless of the quality threshold that has been chosen.", db.profile.never_consider),
		},
		plugins = {
			--profiles = { profiles = LibStub("AceDBOptions-3.0"):GetOptionsTable(db), },
		},
	}
	self.options = options

	LibStub("AceConfigRegistry-3.0"):RegisterOptionsTable("DropTheCheapestThing", options)
	LibStub("AceConfigDialog-3.0"):AddToBlizOptions("DropTheCheapestThing", "DropTheCheapestThing")
	self:RegisterChatCommand("dropcheap", function() LibStub("AceConfigDialog-3.0"):Open("DropTheCheapestThing") end)
end

function module:ShowConfig()
	LibStub("AceConfigDialog-3.0"):Open("DropTheCheapestThing")
end

