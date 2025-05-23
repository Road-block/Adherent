local addonName, adherent = ...
local addon = LibStub("AceAddon-3.0"):NewAddon(adherent, addonName, "AceConsole-3.0", "AceHook-3.0", "AceEvent-3.0", "AceTimer-3.0", "AceBucket-3.0", "AceComm-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale(addonName)
local AC = LibStub("AceConfig-3.0")
local ACD = LibStub("AceConfigDialog-3.0")
local ADBO = LibStub("AceDBOptions-3.0")
local LDB = LibStub("LibDataBroker-1.1"):NewDataObject(addonName)
local LDI = LibStub("LibDBIcon-1.0")
local C = LibStub("LibCrayon-3.0")
local DF = LibStub("LibDeformat-3.0")
local T = LibStub("LibQTip-1.0")

adherent._DEBUG = false
local _,_,_,tocNum = GetBuildInfo()
tocNum = tonumber(tocNum)
adherent._cata = _G.WOW_PROJECT_ID and (_G.WOW_PROJECT_ID == _G.WOW_PROJECT_CATACLYSM_CLASSIC) or false
adherent._classic = _G.WOW_PROJECT_ID and (_G.WOW_PROJECT_ID == _G.WOW_PROJECT_CLASSIC) or false
-- adherent._bcc = _G.WOW_PROJECT_ID and (_G.WOW_PROJECT_ID == _G.WOW_PROJECT_BURNING_CRUSADE_CLASSIC) or false
-- adherent._bcc = adherent._bcc and not adherent._wrath -- temp until we get a wrath project id
adherent._playerName = GetUnitName("player")
adherent._playerFullName = adherent._playerName

local label = string.format("|cff33ff99%s|r",addonName)
local out_chat = string.format("%s: %%s",addonName)
local special_frames = {}
local alreadyPinged, alreadyPonged, pongReceived = {}, {}, {}
local InviteToGroup = _G.InviteToGroup or C_PartyInfo.InviteUnit
local RequestInviteFromUnit = _G.RequestInviteFromUnit or C_PartyInfo.RequestInviteFromUnit
local CanGroupInvite = _G.CanGroupInvite or C_PartyInfo.CanInvite
local ConvertToRaid = _G.ConvertToRaid or C_PartyInfo.ConvertToRaid
local GuildRoster = _G.GuildRoster or C_GuildInfo.GuildRoster
local GetAddOnMetadata = _G.GetAddOnMetadata or C_AddOns.GetAddOnMetadata
local COMM_PREFIX = format("%s_PFX",addonName)

local default_keywords = {
  follow = {"!fme"},
  followstop = {"!fno"},
  groupsend = {"!invme"},
}
local default_emotes = {
  follow =     {L[EMOTE163_TOKEN], L[EMOTE7_TOKEN]},   -- /followme /beckon
  followstop = {L[EMOTE164_TOKEN], L[EMOTE130_TOKEN]}, -- /wait /shoo
  groupsend =  {L[EMOTE382_TOKEN], L[EMOTE112_TOKEN]}, -- /arm /cuddle
}
local defaults = {
  profile = {
    guild = {},
    adherents = {},
  },
  char = {
    suspend = false,
    echo = false,
    inform = true,
    tooltip = true,
    notbusy = false,
    notinstance = false,
    notcombat = false,
    friends = {},
    follow = {
      friend = true,
      guild = true,
      group = false,
      all = false,
      whostarted = false,
      blacklist = {},
      whitelist = {},
      keywords = {
        follow = {},
        followstop = {},
      },
      customonly = false,
      chat = {
        RAID_LEADER = true,
        RAID = true,
        PARTY_LEADER = true,
        PARTY = true,
        SAY = false,
        WHISPER = true,
      },
      TEXT_EMOTE = true,
    },
    groupjoin = {
      friend = true,
      guild = true,
      all = false,
      blacklist = {},
      whitelist = {},
    },
    groupsend = {
      friend = true,
      guild = true,
      autoraid = false,
      blacklist = {},
      whitelist = {},
      keywords = {},
      customonly = false,
      chat = {
        SAY = false,
        WHISPER = true,
      },
      TEXT_EMOTE = true,
    },
    minimap = {
      hide = true,
    },
  },
}

local cmd = {
  type = "group", handler = adherent, args =
  {
    toggle = {
      type = "execute",
      name = L["Toggle"],
      func = function()
        if adherent:IsEnabled() then
          adherent:Disable()
        else
          adherent:Enable()
          adherent.db.char.suspend = false
        end
      end,
      order = 1,
    },
    options = {
      type = "execute",
      name = _G.OPTIONS,
      func = function()
        adherent:showOptions()
      end,
      order = 2,
    },
    known = {
      type = "input",
      name = L["Known"],
      desc = L["Print discovered Adherents.\nUse a partial name to limit results"],
      get = function() end,
      set = function(info, val)
        local filter = val and #(val:gsub("%s",""))>0 and val or ".+"
        for k,v in pairs(adherent.db.profile.adherents) do
          if k:find(filter) then
            adherent:debugPrint(format("%s v%s",k,v))
          end
        end
      end,
      order = 3,
    },
    greet = {
      type = "input",
      name = L["Greet"],
      desc = L["Send a backchannel greeting to a player to discover if they have an Adherent"],
      get = function() end,
      set = function(info, val)
        local name = adherent:GetSlashCmdTarget(val)
        if name and adherent:validName(info, name) then
          adherent:ping(name)
        end
      end,
    }
  }
}

function adherent:options()
  if not (self._options) then
    self._options =
    {
      type = "group",
      handler = adherent,
      args = {
        general = {
          type = "group",
          name = _G.OPTIONS,
          childGroups = "tab",
          args = {
            settings = {
              type = "group",
              name = _G.SETTINGS,
              order = 1,
              args = { },
            },
            acceptfollow = {
              type = "group",
              name = _G.FOLLOW,
              desc = L["Auto follow Options"],
              order = 3,
              args = {
                what = {
                  type = "group",
                  name = format(L["Keywords monitored by %s"],addonName),
                  inline = true,
                  order = 1,
                  args = { },
                },
                where = {
                  type = "group",
                  name = format(L["%s will listen to"],addonName),
                  inline = true,
                  order = 2,
                  args = { },
                },
                who = {
                  type = "group",
                  name = format(L["Who can command %s?"],addonName),
                  inline = true,
                  order = 3,
                  args = { },
                },
              },
            },
            acceptgroup = {
              type = "group",
              name = _G.GROUP,
              desc = L["Auto group Join Options"],
              order = 4,
              args = {
                who = {
                  type = "group",
                  name = L["Auto accept Group Invites from"],
                  inline = true,
                  order = 1,
                  args = { },
                },
              },
            },
            sendgroup = {
              type = "group",
              name = L["Group Invite"],
              desc = L["Auto group Invite Options"],
              order = 5,
              args = {
                what = {
                  type = "group",
                  name = format(L["Keywords monitored by %s"],addonName),
                  inline = true,
                  order = 1,
                  args = { },
                },
                where = {
                  type = "group",
                  name = format(L["%s will listen to"],addonName),
                  inline = true,
                  order = 2,
                  args = { },
                },
                who = {
                  type = "group",
                  name = format(L["Who can command %s?"],addonName),
                  inline = true,
                  order = 3,
                  args = { },
                },
              },
            },
          }
        }
      }
    }
    self._options.args.general.args.settings.args["title"] = {
      type = "header",
      name = _G.HELP_LABEL,
      order = 1,
    }
    self._options.args.general.args.settings.args["usage"] = {
      type = "description",
      fontSize = "medium",
      image = function()
        return LDB.icon or 666623 -- "Interface\\COMMON\\friendship-FistHuman"
      end,
      name = L.USAGE,
      order = 5,
    }
    self._options.args.general.args.settings.args["separator0"] = {
      type = "header",
      name = "",
      order = 6,
    }
    self._options.args.general.args.settings.args["suspend"] = {
      type = "toggle",
      name = format(L["Suspend %s"], addonName),
      desc = format(L["Suspend %s"], addonName),
      order = 10,
      get = function() return adherent.db.char.suspend end,
      set = function(info, val)
        adherent.db.char.suspend = val
        if adherent.db.char.suspend then
          adherent:Disable()
        else
          adherent:Enable()
        end
      end,
    }
    self._options.args.general.args.settings.args["notcombat"] = {
      type = "toggle",
      name = L["Not in Combat"],
      desc = format(L["%s will not automate when you are in Combat"], addonName),
      order = 11,
      get = function() return adherent.db.char.notcombat end,
      set = function(info, val)
        adherent.db.char.notcombat = val
      end,
    }
    self._options.args.general.args.settings.args["notinstance"] = {
      type = "toggle",
      name = L["Not in Instances"],
      desc = format(L["%s will not automate when you are in a PvE Instance"], addonName),
      order = 12,
      get = function() return adherent.db.char.notinstance end,
      set = function(info, val)
        adherent.db.char.notinstance = val
      end,
    }
    self._options.args.general.args.settings.args["notbusy"] = {
      type = "toggle",
      name = L["Not when busy"],
      desc = format(L["%s will not interrupt Trade/Mail/Auction/Bank/Professions/Queues"], addonName),
      order = 13,
      get = function() return adherent.db.char.notbusy end,
      set = function(info, val)
        adherent.db.char.notbusy = val
      end,
    }
    self._options.args.general.args.settings.args["echo"] = {
      type = "toggle",
      name = format(L["Echo %s actions"], addonName),
      desc = format(L["Print %s actions to your chatframe"], addonName),
      order = 14,
      get = function() return adherent.db.char.echo end,
      set = function(info, val)
        adherent.db.char.echo = val
      end,
    }
    self._options.args.general.args.settings.args["inform"] = {
      type = "toggle",
      name = L["Inform Initiator"],
      desc = L["Send a tell to action initiator when accepting or declining"],
      order = 15,
      get = function() return adherent.db.char.inform end,
      set = function(info, val)
        adherent.db.char.inform = val
      end,
    }
    self._options.args.general.args.settings.args["tooltip"] = {
      type = "toggle",
      name = L["Player Tooltip Hint"],
      desc = format(L["Indicate known %s in player tooltips with an icon after their Name|T%s:15|t"], addonName, (LDB.icon or 666623)),
      order = 16,
      get = function() return adherent.db.char.tooltip end,
      set = function(info, val)
        adherent.db.char.tooltip = val
        adherent:tooltipHook()
      end,
    }
    self._options.args.general.args.settings.args["minimap"] = {
      type = "toggle",
      name = L["Hide from Minimap"],
      desc = L["Hide addon Minimap Button."],
      order = 17,
      get = function() return adherent.db.char.minimap.hide end,
      set = function(info, val)
        adherent.db.char.minimap.hide = val
        if adherent.db.char.minimap.hide then
          LDI:Hide(addonName)
        else
          LDI:Show(addonName)
        end
      end
    }
    self._options.args.general.args.settings.args["defaults"] = {
      type = "execute",
      name = _G.RESET_TO_DEFAULT,
      desc = L["|T357854:16|tWarning!|T357854:16|t\nThis action will wipe ALL addon data."],
      func = "resetToDefaults",
      order = 20,
    }
    local acceptfollow_args = self._options.args.general.args.acceptfollow.args
    acceptfollow_args.what.args["desckeywords"] = {
      type = "description",
      name = function()
        local custom_start = table.concat(adherent:table_val_array(adherent.db.char.follow.keywords.follow),", ")
        local custom_stop = table.concat(adherent:table_val_array(adherent.db.char.follow.keywords.followstop),", ")
        if #custom_start > 0 then
          custom_start = format(", |cffffff00%s|r",custom_start)
        else
          custom_start = ""
        end
        if #custom_stop > 0 then
          custom_stop = format(", |cffffff00%s|r",custom_stop)
        else
          custom_stop = ""
        end
        return format(L.DEFAULT_KEYWORDS,custom_start,custom_stop)
      end,
      width = "full",
      order = 1,
    }
    acceptfollow_args.what.args["separator1"] = {
      type = "header",
      name = "",
      order = 2,
    }
    acceptfollow_args.what.args["customonly"] = {
      type = "toggle",
      name = L["Only Custom"],
      desc = L["Only react to |cffffff00custom|r keywords (ignore |cffdcdcdcdefaults|r)"],
      order = 3,
      get = function(info, val)
        return adherent.db.char.follow.customonly
      end,
      set = function(info, val)
        adherent.db.char.follow.customonly = val
      end,
    }
    acceptfollow_args.what.args["kwstartadd"] = {
      type = "input",
      name = L["Follow Keywords"],
      desc = L["Save custom keywords for auto Follow."],
      order = 5,
      get = function(info) return "" end,
      set = function(info, val)
        if not adherent.db.char.follow.keywords.follow[val] then
          adherent.db.char.follow.keywords.follow[val] = val
        end
        adherent:optionsKWHash()
      end,
      validate = function(info, val)
        -- check that it contains at least one control character
        return true
      end,
    }
    acceptfollow_args.what.args["kwstartrem"] = {
      type = "select",
      name = L["Remove Keyword"],
      desc = L["Remove keywords from Custom Keywords"],
      order = 10,
      set = function(info, val)
        if adherent.db.char.follow.keywords.follow[val] then
          adherent.db.char.follow.keywords.follow[val] = nil
        end
        adherent:optionsKWHash()
      end,
      values = function(info)
        return adherent.db.char.follow.keywords.follow
      end,
      disabled = function(info)
        return adherent:table_count(adherent.db.char.follow.keywords.follow) == 0
      end,
    }
    acceptfollow_args.what.args["kwstopadd"] = {
      type = "input",
      name = L["Stop Keywords"],
      desc = L["Save custom keywords for stopping Follow."],
      order = 15,
      get = function(info) return "" end,
      set = function(info, val)
        if not adherent.db.char.follow.keywords.followstop[val] then
          adherent.db.char.follow.keywords.followstop[val] = val
        end
        adherent:optionsKWHash()
      end,
      validate = function(info, val)
        -- check that it contains at least one control character
        return true
      end,
    }
    acceptfollow_args.what.args["kwstoprem"] = {
      type = "select",
      name = L["Remove Keyword"],
      desc = L["Remove keywords from Custom Keywords"],
      order = 20,
      set = function(info, val)
        if adherent.db.char.follow.keywords.followstop[val] then
          adherent.db.char.follow.keywords.followstop[val] = nil
        end
        adherent:optionsKWHash()
      end,
      values = function(info)
        return adherent.db.char.follow.keywords.followstop
      end,
      disabled = function(info)
        return adherent:table_count(adherent.db.char.follow.keywords.followstop) == 0
      end,
    }
    acceptfollow_args.who.args["followstop"] = {
      type = "group",
      name = L["Stop Follow"],
      order = 1,
      inline = false,
      args = {
        whostarteddesc = {
          type = "description",
          name = C:Silver(L.FOLLOWSTOP_DETAIL),
          order = 1,
          width = "full",
        },
        whostarted = {
          type = "toggle",
          name = L["Starter only"],
          order = 2,
          get = function(info, val)
            return adherent.db.char.follow.whostarted
          end,
          set = function(info, val)
            adherent.db.char.follow.whostarted = val
          end
        }
      }
    }
    acceptfollow_args.who.args["friend"] = {
      type = "toggle",
      name = _G.FRIEND,
      order = 5,
      get = function(info, val)
        return adherent.db.char.follow.friend
      end,
      set = function(info, val)
        adherent.db.char.follow.friend = val
      end,
    }
    acceptfollow_args.who.args["guild"] = {
      type = "toggle",
      name = _G.GUILD,
      order = 10,
      get = function(info, val)
        return adherent.db.char.follow.guild
      end,
      set = function(info, val)
        adherent.db.char.follow.guild = val
      end,
    }
    acceptfollow_args.who.args["group"] = {
      type = "toggle",
      name = _G.GROUP,
      order = 15,
      get = function(info, val)
        return adherent.db.char.follow.group
      end,
      set = function(info, val)
        adherent.db.char.follow.group = val
      end,
    }
    acceptfollow_args.who.args["all"] = {
      type = "toggle",
      name = L["Anyone"],
      order = 20,
      get = function(info, val)
        return adherent.db.char.follow.all
      end,
      set = function(info, val)
        adherent.db.char.follow.all = val
      end,
    }
    acceptfollow_args.who.args["separator2"] = {
      type = "header",
      name = "",
      order = 22,
    }
    acceptfollow_args.who.args["blacklistadd"] = {
      type = "input",
      name = L["Add to Blacklist"],
      desc = format(L["Names of players you never want to permit control of %s.\nSupercedes other options."],addonName),
      order = 25,
      get = function(info) return "" end,
      set = function(info, val)
        if val~="" then
          adherent:blacklist(val,"follow","+")
        end
      end,
      validate = "validName",
    }
    acceptfollow_args.who.args["blacklistrem"] = {
      type = "select",
      name = L["Remove from Blacklist"],
      desc = L["Remove a player from Blacklist."],
      order = 30,
      set = function(info, val)
        if val~="" then
          adherent:blacklist(val,"follow","-")
        end
      end,
      disabled = function(info)
        return adherent:table_count(adherent.db.char.follow.blacklist) == 0
      end,
      values = function(info)
        return adherent.db.char.follow.blacklist
      end,
    }
    acceptfollow_args.who.args["blacklistcopy"] = {
      type = "select",
      name = L["Copy from another Blacklist"],
      desc = L["Copies the contents from another Blacklist\n|cffff0000Warning|r: Current contents will be overwritten!"],
      order = 35,
      set = function(info, val)
        adherent.db.char.follow.blacklist = CopyTable(adherent.db.char[val].blacklist,true)
      end,
      values = { groupjoin = _G.GROUP, groupsend = L["Group Invite"] },
    }
    acceptfollow_args.who.args["whitelistadd"] = {
      type = "input",
      name = L["Add to Whitelist"],
      desc = L["Names of players you always want to permit control.\nSupercedes other options except Blacklist."],
      order = 40,
      get = function(info) return "" end,
      set = function(info, val)
        if val~="" then
          adherent:whitelist(val,"follow","+")
        end
      end,
      validate = "validName",
    }
    acceptfollow_args.who.args["whitelistrem"] = {
      type = "select",
      name = L["Remove from Whitelist"],
      desc = L["Remove a player from Whitelist."],
      order = 45,
      set = function(info, val)
        if val~="" then
          adherent:whitelist(val,"follow","-")
        end
      end,
      disabled = function(info)
        return adherent:table_count(adherent.db.char.follow.whitelist) == 0
      end,
      values = function(info)
        return adherent.db.char.follow.whitelist
      end,
    }
    acceptfollow_args.who.args["whitelistcopy"] = {
      type = "select",
      name = L["Copy from another Whitelist"],
      desc = L["Copies the contents from another Whitelist\n|cffff0000Warning|r: Current contents will be overwritten!"],
      order = 47,
      set = function(info, val)
        adherent.db.char.follow.whitelist = CopyTable(adherent.db.char[val].whitelist,true)
      end,
      values = { groupjoin = _G.GROUP, groupsend = L["Group Invite"] },
    }
    acceptfollow_args.where.args["emote"] = {
      type = "toggle",
      name = _G.EMOTE,
      desc = L["React to Emotes."],
      order = 1,
      get = function(info, val)
        return adherent.db.char.follow.TEXT_EMOTE
      end,
      set = function(info, val)
        adherent.db.char.follow.TEXT_EMOTE = val
      end,
    }
    acceptfollow_args.where.args["descemotes"] = {
      type = "description",
      name = format(L.DEFAULT_EMOTES,string.lower(_G.EMOTE163_TOKEN),string.lower(_G.EMOTE7_TOKEN),string.lower(_G.EMOTE164_TOKEN),string.lower(_G.EMOTE130_TOKEN)),
      width = "double",
      order = 5,
    }
    acceptfollow_args.where.args["chat"] = {
      type = "multiselect",
      dialogControl = "Dropdown",
      name = L["Keywords in Chat"],
      desc = format(L["Which channels should %s monitor?"],addonName),
      order = 10,
      get = function(info, key)
        return adherent.db.char.follow.chat[key]
      end,
      set = function(info, key, val)
        adherent.db.char.follow.chat[key] = val
        if key == "PARTY" or key == "RAID" then
          adherent.db.char.follow.chat[key.."_LEADER"] = val
        end
      end,
      values = {
        PARTY = _G.PARTY,
        RAID = _G.RAID,
        SAY = _G.SAY,
        WHISPER = _G.WHISPER,
      },
    }
    local acceptgroup_args = self._options.args.general.args.acceptgroup.args
    acceptgroup_args.who.args["friend"] = {
      type = "toggle",
      name = _G.FRIEND,
      order = 5,
      get = function(info, val)
        return adherent.db.char.groupjoin.friend
      end,
      set = function(info, val)
        adherent.db.char.groupjoin.friend = val
      end,
    }
    acceptgroup_args.who.args["guild"] = {
      type = "toggle",
      name = _G.GUILD,
      order = 10,
      get = function(info, val)
        return adherent.db.char.groupjoin.guild
      end,
      set = function(info, val)
        adherent.db.char.groupjoin.guild = val
      end,
    }
    acceptgroup_args.who.args["all"] = {
      type = "toggle",
      name = L["Anyone"],
      order = 20,
      get = function(info, val)
        return adherent.db.char.groupjoin.all
      end,
      set = function(info, val)
        adherent.db.char.groupjoin.all = val
      end,
    }
    acceptgroup_args.who.args["separator2"] = {
      type = "header",
      name = "",
      order = 22,
    }
    acceptgroup_args.who.args["blacklistadd"] = {
      type = "input",
      name = L["Add to Blacklist"],
      desc = format(L["Names of players you never want to permit control of %s.\nSupercedes other options."],addonName),
      order = 25,
      get = function(info) return "" end,
      set = function(info, val)
        if val~="" then
          adherent:blacklist(val,"groupjoin","+")
        end
      end,
      validate = "validName",
    }
    acceptgroup_args.who.args["blacklistrem"] = {
      type = "select",
      name = L["Remove from Blacklist"],
      desc = L["Remove a player from Blacklist."],
      order = 30,
      set = function(info, val)
        if val~="" then
          adherent:blacklist(val,"groupjoin","-")
        end
      end,
      disabled = function(info)
        return adherent:table_count(adherent.db.char.groupjoin.blacklist) == 0
      end,
      values = function(info)
        return adherent.db.char.groupjoin.blacklist
      end,
    }
    acceptgroup_args.who.args["blacklistcopy"] = {
      type = "select",
      name = L["Copy from another Blacklist"],
      desc = L["Copies the contents from another Blacklist\n|cffff0000Warning|r: Current contents will be overwritten!"],
      order = 35,
      set = function(info, val)
        adherent.db.char.groupjoin.blacklist = CopyTable(adherent.db.char[val].blacklist,true)
      end,
      values = { follow = _G.FOLLOW, groupsend = L["Group Invite"] },
    }
    acceptgroup_args.who.args["whitelistadd"] = {
      type = "input",
      name = L["Add to Whitelist"],
      desc = L["Names of players you always want to permit control.\nSupercedes other options except Blacklist."],
      order = 40,
      get = function(info) return "" end,
      set = function(info, val)
        if val~="" then
          adherent:whitelist(val,"groupjoin","+")
        end
      end,
      validate = "validName",
    }
    acceptgroup_args.who.args["whitelistrem"] = {
      type = "select",
      name = L["Remove from Whitelist"],
      desc = L["Remove a player from Whitelist."],
      order = 45,
      set = function(info, val)
        if val~="" then
          adherent:whitelist(val,"groupjoin","-")
        end
      end,
      disabled = function(info)
        return adherent:table_count(adherent.db.char.groupjoin.whitelist) == 0
      end,
      values = function(info)
        return adherent.db.char.groupjoin.whitelist
      end,
    }
    acceptgroup_args.who.args["whitelistcopy"] = {
      type = "select",
      name = L["Copy from another Whitelist"],
      desc = L["Copies the contents from another Whitelist\n|cffff0000Warning|r: Current contents will be overwritten!"],
      order = 47,
      set = function(info, val)
        adherent.db.char.follow.whitelist = CopyTable(adherent.db.char[val].whitelist,true)
      end,
      values = { follow = _G.FOLLOW, groupsend = L["Group Invite"] },
    }
    local sendgroup_args = self._options.args.general.args.sendgroup.args
    sendgroup_args.what.args["desckeywords"] = {
      type = "description",
      name = function()
        local custom_send = table.concat(adherent:table_val_array(adherent.db.char.groupsend.keywords),", ")
        if #custom_send > 0 then
          custom_send = format(", |cffffff00%s|r",custom_send)
        else
          custom_send = ""
        end
        return format(L.DEFAULT_KEYWORDS_GROUP,custom_send)
      end,
      width = "full",
      order = 1,
    }
    sendgroup_args.what.args["separator1"] = {
      type = "header",
      name = "",
      order = 2,
    }
    sendgroup_args.what.args["customonly"] = {
      type = "toggle",
      name = L["Only Custom"],
      desc = L["Only react to |cffffff00custom|r keywords (ignore |cffdcdcdcdefaults|r)"],
      order = 3,
      get = function(info, val)
        return adherent.db.char.groupsend.customonly
      end,
      set = function(info, val)
        adherent.db.char.groupsend.customonly = val
      end,
    }
    sendgroup_args.what.args["kwstartadd"] = {
      type = "input",
      name = L["Send Group Invite Keywords"],
      desc = L["Save custom keywords for auto Group Invite."],
      order = 5,
      get = function(info) return "" end,
      set = function(info, val)
        if not adherent.db.char.groupsend.keywords[val] then
          adherent.db.char.groupsend.keywords[val] = val
        end
        adherent:optionsKWHash()
      end,
      validate = function(info, val)
        -- check that it contains at least one control character
        return true
      end,
    }
    sendgroup_args.what.args["kwstartrem"] = {
      type = "select",
      name = L["Remove Keyword"],
      desc = L["Remove keywords from Custom Keywords"],
      order = 10,
      set = function(info, val)
        if adherent.db.char.groupsend.keywords[val] then
          adherent.db.char.groupsend.keywords[val] = nil
        end
        adherent:optionsKWHash()
      end,
      values = function(info)
        return adherent.db.char.groupsend.keywords
      end,
      disabled = function(info)
        return adherent:table_count(adherent.db.char.groupsend.keywords) == 0
      end,
    }
    sendgroup_args.who.args["friend"] = {
      type = "toggle",
      name = _G.FRIEND,
      order = 5,
      get = function(info, val)
        return adherent.db.char.groupsend.friend
      end,
      set = function(info, val)
        adherent.db.char.groupsend.friend = val
      end,
    }
    sendgroup_args.who.args["guild"] = {
      type = "toggle",
      name = _G.GUILD,
      order = 10,
      get = function(info, val)
        return adherent.db.char.groupsend.guild
      end,
      set = function(info, val)
        adherent.db.char.groupsend.guild = val
      end,
    }
    sendgroup_args.who.args["separator2"] = {
      type = "header",
      name = "",
      order = 22,
    }
    sendgroup_args.who.args["blacklistadd"] = {
      type = "input",
      name = L["Add to Blacklist"],
      desc = format(L["Names of players you never want to permit control of %s.\nSupercedes other options."],addonName),
      order = 25,
      get = function(info) return "" end,
      set = function(info, val)
        if val~="" then
          adherent:blacklist(val,"groupsend","+")
        end
      end,
      validate = "validName",
    }
    sendgroup_args.who.args["blacklistrem"] = {
      type = "select",
      name = L["Remove from Blacklist"],
      desc = L["Remove a player from Blacklist."],
      order = 30,
      set = function(info, val)
        if val~="" then
          adherent:blacklist(val,"groupsend","-")
        end
      end,
      disabled = function(info)
        return adherent:table_count(adherent.db.char.groupsend.blacklist) == 0
      end,
      values = function(info)
        return adherent.db.char.groupsend.blacklist
      end,
    }
    sendgroup_args.who.args["blacklistcopy"] = {
      type = "select",
      name = L["Copy from another Blacklist"],
      desc = L["Copies the contents from another Blacklist\n|cffff0000Warning|r: Current contents will be overwritten!"],
      order = 35,
      set = function(info, val)
        adherent.db.char.groupsend.blacklist = CopyTable(adherent.db.char[val].blacklist,true)
      end,
      values = { follow = _G.FOLLOW, groupjoin = _G.GROUP },
    }
    sendgroup_args.who.args["whitelistadd"] = {
      type = "input",
      name = L["Add to Whitelist"],
      desc = L["Names of players you always want to permit control.\nSupercedes other options except Blacklist."],
      order = 40,
      get = function(info) return "" end,
      set = function(info, val)
        if val~="" then
          adherent:whitelist(val,"groupsend","+")
        end
      end,
      validate = "validName",
    }
    sendgroup_args.who.args["whitelistrem"] = {
      type = "select",
      name = L["Remove from Whitelist"],
      desc = L["Remove a player from Whitelist."],
      order = 45,
      set = function(info, val)
        if val~="" then
          adherent:whitelist(val,"groupsend","-")
        end
      end,
      disabled = function(info)
        return adherent:table_count(adherent.db.char.groupsend.whitelist) == 0
      end,
      values = function(info)
        return adherent.db.char.groupsend.whitelist
      end,
    }
    sendgroup_args.who.args["whitelistcopy"] = {
      type = "select",
      name = L["Copy from another Whitelist"],
      desc = L["Copies the contents from another Whitelist\n|cffff0000Warning|r: Current contents will be overwritten!"],
      order = 47,
      set = function(info, val)
        adherent.db.char.groupsend.whitelist = CopyTable(adherent.db.char[val].whitelist,true)
      end,
      values = { follow = _G.FOLLOW, groupjoin = _G.GROUP },
    }
    sendgroup_args.where.args["emote"] = {
      type = "toggle",
      name = _G.EMOTE,
      desc = L["React to Emotes."],
      order = 1,
      get = function(info, val)
        return adherent.db.char.groupsend.TEXT_EMOTE
      end,
      set = function(info, val)
        adherent.db.char.groupsend.TEXT_EMOTE = val
      end,
    }
    sendgroup_args.where.args["descemotes"] = {
      type = "description",
      name = format(L.DEFAULT_EMOTES_GROUP,string.lower(_G.EMOTE382_TOKEN),string.lower(_G.EMOTE112_TOKEN)),
      width = "double",
      order = 5,
    }
    sendgroup_args.where.args["chat"] = {
      type = "multiselect",
      dialogControl = "Dropdown",
      name = L["Keywords in Chat"],
      desc = format(L["Which channels should %s monitor?"],addonName),
      order = 10,
      get = function(info, key)
        return adherent.db.char.groupsend.chat[key]
      end,
      set = function(info, key, val)
        adherent.db.char.groupsend.chat[key] = val
      end,
      values = {
        SAY = _G.SAY,
        WHISPER = _G.WHISPER,
      },
    }
    sendgroup_args.where.args["autoraid"] = {
      type = "toggle",
      name = _G.CONVERT_TO_RAID,
      desc = L["Automatically convert to raid when party full."],
      order = 12,
      get = function(info, val)
        return adherent.db.char.groupsend.autoraid
      end,
      set = function(info, val)
        adherent.db.char.groupsend.autoraid = val
      end,
    }
  end
  return self._options
end

function adherent.OnLDBClick(obj,button)
  if button == "LeftButton" then
    adherent:showOptions()
  elseif button == "RightButton" then
    if adherent:IsEnabled() then
      adherent:Disable()
    else
      adherent:Enable()
      adherent.db.char.suspend = false
    end
    adherent.CreateTooltip(obj)
  end
end

function adherent:QuickSettings(data)
  local option = data.option
  adherent.db.char[option] = not adherent.db.char[option]
  adherent.CreateTooltip(data.parent)
end

function adherent.CreateTooltip(parent, data)
  --tooltip = tooltip or GameTooltip
  if T:IsAcquired(addonName) then
    adherent.qtip:Clear()
  else
    adherent.qtip = T:Acquire(addonName, 3, "CENTER", "CENTER", "CENTER")
    adherent.qtip:SmartAnchorTo(parent)
    adherent.qtip:SetAutoHideDelay(0.2, parent)
  end

  if _G.TipTac and _G.TipTac.AddModifiedTip then
    _G.TipTac:AddModifiedTip(adherent.qtip, true)
  elseif _G.AddOnSkins and _G.AddOnSkins.SkinTooltip then
    _G.AddOnSkins:SkinTooltip(adherent.qtip)
  elseif _G.TinyTooltip then
    -- unfortunately TinyTooltip installs hooks for skinning and LibQTip blocks those
  end

  local line = adherent.qtip:AddLine()
  local header = adherent.db.char.suspend and adherent._labelfull..C:Red(L["[Suspended]"]) or adherent._labelfull
  local header_font = adherent.qtip:GetHeaderFont()
  adherent.qtip:SetCell(line,1,header,header_font,"CENTER",0)
  adherent.qtip:AddSeparator(4,0,0,0,0)
  line = adherent.qtip:AddLine()
  adherent.qtip:SetCell(line, 1, C:Yellow(L["Quick Settings"]),header_font, "CENTER",0)
  adherent.qtip:AddSeparator()
  line = adherent.qtip:AddLine()
  local texture = adherent.db.char.notbusy and 136814 or 136813
  adherent.qtip:SetCell(line, 1, format("|T%s:12:12:0:0|t %s",texture,C:Cyan(L["Not when busy"])), nil, "CENTER", 0)
  adherent.qtip:SetLineScript(line, "OnMouseUp", adherent.QuickSettings, {parent=parent, option="notbusy"})
  line = adherent.qtip:AddLine()
  texture = adherent.db.char.notcombat and 136814 or 136813
  adherent.qtip:SetCell(line, 1, format("|T%s:12:12:0:0|t %s",texture,C:Cyan(L["Not in Combat"])), nil, "CENTER", 0)
  adherent.qtip:SetLineScript(line, "OnMouseUp", adherent.QuickSettings, {parent=parent, option="notcombat"})
  line = adherent.qtip:AddLine()
  texture = adherent.db.char.notinstance and 136814 or 136813
  adherent.qtip:SetCell(line, 1, format("|T%s:12:12:0:0|t %s",texture,C:Cyan(L["Not in Instances"])), nil, "CENTER", 0)
  adherent.qtip:SetLineScript(line, "OnMouseUp", adherent.QuickSettings, {parent=parent, option="notinstance"})
  line = adherent.qtip:AddLine()
  texture = adherent.db.char.inform and 136814 or 136813
  adherent.qtip:SetCell(line, 1, format("|T%s:12:12:0:0|t %s",texture,C:Cyan(L["Inform Initiator"])), nil, "CENTER", 0)
  adherent.qtip:SetLineScript(line, "OnMouseUp", adherent.QuickSettings, {parent=parent, option="inform"})

  adherent.qtip:AddSeparator(4,0,0,0,0)
  line = adherent.qtip:AddLine()
  adherent.qtip:SetCell(line,1,C:Copper(L["Left Click"]).." || "..C:Yellow(L["Blizzard Options"]),nil,"CENTER",0)
  line = adherent.qtip:AddLine()
  adherent.qtip:SetCell(line,1,C:Copper(L["Right Click"]).." || "..C:Yellow(format(L["Suspend %s"],addonName)),nil,"CENTER",0)
  adherent.qtip:UpdateScrolling()
  adherent.qtip:Show()
end

function adherent:OnInitialize() -- 1. ADDON_LOADED
  self._versionString = GetAddOnMetadata(addonName,"Version")
  self._websiteString = GetAddOnMetadata(addonName,"X-Website")
  self._labelfull = string.format("%s %s",label,self._versionString)
  self.db = LibStub("AceDB-3.0"):New("AdherentDB", defaults)

  self:options()
  self._options.args.profile = ADBO:GetOptionsTable(self.db)
  self._options.args.profile.guiHidden = true
  self._options.args.profile.cmdHidden = true

  AC:RegisterOptionsTable(addonName.."_cmd", cmd, {"adherent"})
  AC:RegisterOptionsTable(addonName, self._options)

  self.blizzoptions = ACD:AddToBlizOptions(addonName,nil,nil,"general")
  self.blizzoptions.profile = ACD:AddToBlizOptions(addonName, "Profiles", addonName, "profile")
  self.db.RegisterCallback(self, "OnProfileChanged", "RefreshConfig")

  self.db.RegisterCallback(self, "OnProfileCopied", "RefreshConfig")
  self.db.RegisterCallback(self, "OnProfileReset", "RefreshConfig")
  LDB.type = "launcher"
  LDB.text = label
  LDB.label = label -- string.format("%s %s",addonName,self._versionString)
  LDB.icon = 666623 -- "Interface\\COMMON\\friendship-FistHuman" -- UI-GuildButton-MOTD-Disabled
  LDB.OnClick = adherent.OnLDBClick
  LDB.OnEnter = adherent.CreateTooltip
  LDI:Register(addonName, LDB, adherent.db.char.minimap)
end

function adherent:OnEnable() -- 2. PLAYER_LOGIN
  self._playerFullName = string.format("%s-%s", UnitFullName("player"))
  if IsInGuild() then
    local guildname = GetGuildInfo("player")
    if not guildname then
      GuildRoster()
    end
    self._bucketGuildRoster = self:RegisterBucketEvent("GUILD_ROSTER_UPDATE",3.0)
  else
    self:RegisterEvent("PLAYER_GUILD_UPDATE")
    self:ScheduleTimer("deferredInit",5)
  end
  local faction = UnitFactionGroup("player")
  if faction == PLAYER_FACTION_GROUP[0] then -- horde
    LDB.icon = 666624 -- "Interface\\COMMON\\friendship-FistOrc" -- 666624
  else
    LDB.icon = 666623 -- "Interface\\COMMON\\friendship-FistHuman" -- 666623
  end
  self._bucketFriendRoster = self:RegisterBucketEvent("FRIENDLIST_UPDATE",5.0)
  self:FRIENDLIST_UPDATE()
  self:RegisterEvent("PARTY_INVITE_REQUEST")
  self:RegisterEvent("PLAYER_FLAGS_CHANGED")
  self:PLAYER_FLAGS_CHANGED("PLAYER_FLAGS_CHANGED","player")

  self:RegisterEvent("CHAT_MSG_RAID_LEADER", "CHAT_MSG_EVENT")
  self:RegisterEvent("CHAT_MSG_RAID", "CHAT_MSG_EVENT")
  self:RegisterEvent("CHAT_MSG_PARTY_LEADER", "CHAT_MSG_EVENT")
  self:RegisterEvent("CHAT_MSG_PARTY", "CHAT_MSG_EVENT")
  self:RegisterEvent("CHAT_MSG_SAY", "CHAT_MSG_EVENT")
  self:RegisterEvent("CHAT_MSG_TEXT_EMOTE", "CHAT_MSG_EVENT")
  self:RegisterEvent("CHAT_MSG_WHISPER", "CHAT_MSG_EVENT")

  self:RegisterComm(COMM_PREFIX)
  self:tooltipHook()

  self:defaultKWHash()
  self:optionsKWHash()
  self:Print(C:Green(L["[Enabled]"]))
end

function adherent:OnDisable() -- ADHOC
  self.db.char.suspend = true
  self:Print(C:Red(L["[Suspended]"]))
end

function adherent:RefreshConfig()

end

function adherent:deferredInit(guildname)
  if self._initdone then return end
  local realmname = GetRealmName()
  if not realmname then return end
  local panelHeader = _G.OPTIONS
  self:parseVersion(adherent._versionString)
  local major_ver = self._version.major
  local addonMsg = string.format("VER;%s;%d",adherent._versionString,major_ver)
  if guildname then
    self._guildName = guildname
    local profilekey = guildname.." - "..realmname
    self._options.name = self._labelfull
    self._options.args.general.name = panelHeader
    self.db:SetProfile(profilekey)
    -- version check
    self:addonMessage(addonMsg,"GUILD")
    self._initdone = true
  else
    local profilekey = realmname
    self._options.name = self._labelfull
    self._options.args.general.name = panelHeader
    self.db:SetProfile(profilekey)
    self._initdone = true
  end
  self:ScheduleTimer("addonMessage",1,addonMsg,"YELL")
end

function adherent:showOptions()
  if ACD.OpenFrames[addonName] then
    ACD:Close(addonName)
  else
    ACD:Open(addonName,"general")
  end
end

function adherent:debugPrint(msg,onlyWhenDebug)
  if onlyWhenDebug and not self._DEBUG then return end
  if not self._debugchat then
    for i=1,NUM_CHAT_WINDOWS do
      local tab = _G["ChatFrame"..i.."Tab"]
      local cf = _G["ChatFrame"..i]
      local tabName = tab:GetText()
      if tab ~= nil and (tabName:lower() == "debug") then
        self._debugchat = cf
        ChatFrame_RemoveAllMessageGroups(self._debugchat)
        ChatFrame_RemoveAllChannels(self._debugchat)
        self._debugchat:SetMaxLines(1024)
        break
      end
    end
  end
  if self._debugchat then
    self:Print(self._debugchat,msg)
  else
    self:Print(msg)
  end
end

function adherent:parseVersion(version,otherVersion)
  if not adherent._version then adherent._version = {} end
  for major,minor,patch in string.gmatch(version,"(%d+)[^%d]?(%d*)[^%d]?(%d*)") do
    adherent._version.major = tonumber(major)
    adherent._version.minor = tonumber(minor)
    adherent._version.patch = tonumber(patch)
  end
  if (otherVersion) then
    if not adherent._otherversion then adherent._otherversion = {} end
    for major,minor,patch in string.gmatch(otherVersion,"(%d+)[^%d]?(%d*)[^%d]?(%d*)") do
      adherent._otherversion.major = tonumber(major)
      adherent._otherversion.minor = tonumber(minor)
      adherent._otherversion.patch = tonumber(patch)
    end
    if (adherent._otherversion.major ~= nil and adherent._version.major ~= nil) then
      if (adherent._otherversion.major < adherent._version.major) then -- we are newer
        return
      elseif (adherent._otherversion.major > adherent._version.major) then -- they are newer
        return true, "major"
      else -- tied on major, go minor
        if (adherent._otherversion.minor ~= nil and adherent._version.minor ~= nil) then
          if (adherent._otherversion.minor < adherent._version.minor) then -- we are newer
            return
          elseif (adherent._otherversion.minor > adherent._version.minor) then -- they are newer
            return true, "minor"
          else -- tied on minor, go patch
            if (adherent._otherversion.patch ~= nil and adherent._version.patch ~= nil) then
              if (adherent._otherversion.patch < adherent._version.patch) then -- we are newer
                return
              elseif (adherent._otherversion.patch > adherent._version.patch) then -- they are newwer
                return true, "patch"
              end
            elseif (adherent._otherversion.patch ~= nil and adherent._version.patch == nil) then -- they are newer
              return true, "patch"
            end
          end
        elseif (adherent._otherversion.minor ~= nil and adherent._version.minor == nil) then -- they are newer
          return true, "minor"
        end
      end
    end
  end
end

function adherent:make_escable(object,operation)
  if type(object) == "string" then
    local found
    for i,f in ipairs(UISpecialFrames) do
      if f==object then
        found = i
      end
    end
    if not found and operation=="add" then
      table.insert(UISpecialFrames,object)
    elseif found and operation=="remove" then
      table.remove(UISpecialFrames,found)
    end
  elseif type(object) == "table" then
    if object.Hide then
      local key = tostring(object):gsub("table: ","")
      if operation == "add" then
        special_frames[key] = object
      else
        special_frames[key] = nil
      end
    end
  end
end

function adherent:defaultKWHash()
  self._defKWHash = self._defKWHash or {}
  for action, keywords in pairs(default_keywords) do
    for _, word in pairs(keywords) do
      self._defKWHash[word] = action
    end
  end
end

function adherent:optionsKWHash()
  self._optKWHash = wipe(self._optKWHash or {})
  for k,v in pairs(self.db.char.follow.keywords.follow) do
    self._optKWHash[k] = "follow"
  end
  for k,v in pairs(self.db.char.follow.keywords.followstop) do
    self._optKWHash[k] = "followstop"
  end
  for k,v in pairs(self.db.char.groupsend.keywords) do
    self._optKWHash[k] = "groupsend"
  end
end

function adherent:inform(name, msg, action, ...)
  if not self.db.char.inform then return end
  if msg and action then
    msg = format(msg,action,...)
  end
  if (not msg) and action then
    -- construct msg from action
  end
  if msg and #msg > 0 then
    msg = format(L["<%s> says %s"],addonName,msg)
    SendChatMessage(msg,"WHISPER",nil,name)
  end
end

function adherent:echo(msg, action, ...)
  if not self.db.char.echo then return end
  if msg and action then
    msg = format(msg,action,...)
  end
  if (not msg) and action then
    -- construct msg from action
  end
  if msg and #msg > 0 then
    self:debugPrint(msg)
  end
end

function adherent:follow(unit)
  FollowUnit(unit, true)
end

function adherent:followstop(name)
  local started_by_adherent = self._lastLeader
  local rq_from_starter = name == started_by_adherent
  if rq_from_starter or not adherent.db.char.follow.whostarted then
    FollowUnit("player")
    adherent._lastLeader = nil
    self:echo(L["Request to stop following by %s"],name)
  else
    self:inform(name,L["Can't auto-accept due to \'%s\' option"],L["Starter only"])
  end
end

local function takeAction(action, name)
  if adherent.db.char.notcombat and adherent:combat() then
    adherent:inform(name,L["Can't auto-accept due to \'%s\' option"],L["Not in Combat"])
    return
  end
  if adherent.db.char.notinstance and adherent:instance() then
    adherent:inform(name,L["Can't auto-accept due to \'%s\' option"],L["Not in Instances"])
    return
  end
  if adherent.db.char.notbusy and adherent:busy() then
    adherent:inform(name,L["Can't auto-accept due to \'%s\' option"],L["Not when busy"])
    return
  end
  if action == "follow" then
    adherent:RegisterEvent("UI_ERROR_MESSAGE")
    adherent._lastBidder = name
    adherent:RegisterEvent("AUTOFOLLOW_BEGIN")
    adherent:ScheduleTimer("follow", 0.2, name)
  elseif action == "followstop" then
    adherent:followstop(name)
  elseif action == "groupsend" then
    if CanGroupInvite() then
      adherent:groupinvite(name)
    end
  end
end

function adherent:groupinvite(name)
  local autoconvert = self.db.char.groupsend.autoraid
  local numGroup = GetNumGroupMembers()
  local shouldConvert = (numGroup > MAX_PARTY_MEMBERS) and (not IsInRaid()) and UnitIsGroupLeader("player")
  if shouldConvert and autoconvert then
    ConvertToRaid()
    self:ScheduleTimer("groupinvite",1,name)
    return
  else
    InviteToGroup(name)
    adherent:echo(L["Sending invite to %s."], name)
  end
end

function adherent:Dispatch(action, sender, chatType)
  self:remoteDiscovery(sender)
  local list = action
  if action == "followstop" then
    list = "follow"
  end
  local is_blacklisted = self.db.char[list].blacklist[sender]
  if is_blacklisted then
    return
  end
  local is_whitelisted = self.db.char[list].whitelist[sender]
  if is_whitelisted then -- skip other checks and try action
    takeAction(action, sender)
    return
  end
  local is_guild = self.db.profile.guild[sender]
  local is_friend = self.db.char.friends[sender]
  if action == "follow" or action == "followstop" then
    local listening
    if chatType == "TEXT_EMOTE" then
      listening = self.db.char.follow[chatType]
    else
      listening = self.db.char.follow.chat[chatType]
    end
    if listening then
      if self.db.char.follow.all or (self.db.char.follow.guild and is_guild) or (self.db.char.follow.friend and is_friend) or (self.db.char.follow.group and self:group(sender)) then
        takeAction(action, sender)
        return
      end
    end
  elseif action == "groupsend" then
    local listening
    if chatType == "TEXT_EMOTE" then
      listening = self.db.char[action][chatType]
    else
      listening = self.db.char[action].chat[chatType]
    end
    if listening then
      if (self.db.char[action].guild and is_guild) or (self.db.char[action].friend and is_friend) then
        takeAction(action, sender)
        return
      end
    end
  end
end

function adherent:parseChat(msg)
  local action
  local action_default = self._defKWHash[msg]
  local action_custom = self._optKWHash[msg]
  local custom_only_follow = self.db.char.follow.customonly
  local custom_only_groupsend = self.db.char.groupsend.customonly
  if action_default then
    if ( (action_default == "follow" or action_default == "followstop") and custom_only_follow ) or
       (action_default == "groupsend" and custom_only_groupsend) then
    else
      action = action_default
    end
  end
  return action_custom or action
end

function adherent:parseEmote(msg, sender)
  for action, emotelist in pairs(default_emotes) do
    for _, emote in pairs(emotelist) do
      local name = DF.Deformat(msg, emote)
      if name == sender then
        return action
      end
    end
  end
end

function adherent:tooltipHook()
  if self.db.char.tooltip then
    if not self:IsHooked(GameTooltip, "OnTooltipSetUnit") then
      self:SecureHookScript(GameTooltip, "OnTooltipSetUnit", "addTipHint")
    end
  else
    if self:IsHooked(GameTooltip, "OnTooltipSetUnit") then
      self:Unhook(GameTooltip, "OnTooltipSetUnit")
    end
  end
end

function adherent:addTipHint(tooltip)
  local name, unit = tooltip:GetUnit()
  local tipName = tooltip:GetName()
  if name and unit then
    name = Ambiguate(name, "short")
    local is_known = self.db.profile.adherents[name]
    if UnitIsPlayer(unit) and is_known then
      local old = _G[tipName.."TextLeft1"]:GetText() or ""
      local h = _G[tipName.."TextLeft1"]:GetLineHeight()+4
      _G[tipName.."TextLeft1"]:SetFormattedText("%s|T%s:%d|t",old,LDB.icon,h)
    end
  end
end

function adherent:blacklist(unit, list, action)
  if not unit or unit == "" then return end
  local blacklist, whitelist, name
  if action == "+" then
    blacklist = self.db.char[list].blacklist
    whitelist = self.db.char[list].whitelist
    name = GetUnitName(unit)
    if not name or (name == _G.UNKNOWNOBJECT) or (name == "") then
      name = unit
    end
    if whitelist[name] then
      whitelist[name] = nil
    end
    if not blacklist[name] then
      blacklist[name] = name
    end
  end
  if action == "-" then
    blacklist = self.db.char[list].blacklist
    if blacklist[unit] then
      blacklist[unit] = nil
    end
  end
end

function adherent:whitelist(unit,list,action)
  if not unit or unit == "" then return end
  local whitelist,blacklist,name
  if action == "+" then
    whitelist = self.db.char[list].whitelist
    blacklist = self.db.char[list].blacklist
    name = GetUnitName(unit)
    if not name or (name == _G.UNKNOWNOBJECT) or (name == "") then
      name = unit
    end
    if blacklist[name] then
      blacklist[name] = nil
    end
    if not whitelist[name] then
      whitelist[name] = name
    end
  end
  if action == "-" then
    whitelist = self.db.char[list].whitelist
    if whitelist[unit] then
      whitelist[unit] = nil
    end
  end
end

function adherent:resetToDefaults()
  -- wipe custom lists and reset all options to defaults
  self.db:ResetDB()
end

function adherent:group(unit)
  if not unit then return false end
  if not IsInGroup() then
    return false
  else
    return UnitInParty(unit) or UnitInRaid(unit)
  end
end

local bg_queued = function()
  for i=1, MAX_BATTLEFIELD_QUEUES do
    local status = GetBattlefieldStatus(i)
    if status and (status == "queued" or status == "confirm") then
      return true
    end
  end
  return false
end
function adherent:busy()
  local _, _, _, _, _, tradeskillChannel = UnitChannelInfo("player")
  local _, _, _, _, _, tradeskillCast = UnitCastingInfo("player")
  local crafting = (_G.TradeSkillFrame and _G.TradeSkillFrame:IsVisible()) or (_G.CraftFrame and _G.CraftFrame:IsVisible())
  local professions = crafting or tradeskillChannel or tradeskillCast
  local interacting = UnitName("npc")
  local lfgqueue = _G.C_LFGList and _G.C_LFGList.HasActiveEntryInfo()
  local bgqueue = bg_queued()
  local in_queue = lfgqueue or bgqueue
  local wouldleave = _G.WillAcceptInviteRemoveQueues()
  local dnd = UnitIsDND("player")
  if interacting or professions or in_queue or wouldleave or dnd then
    return true
  end
  return false
end

function adherent:combat()
  return UnitAffectingCombat("player")
end

function adherent:instance()
  local inst, insType = IsInInstance()
  return inst and (insType == "raid" or insType == "party")
end

local function acceptGroup(reason, sender)
  if adherent.db.char.notbusy and adherent:busy() then
    adherent:inform(sender,L["Can't auto-accept due to \'%s\' option"],L["Not when busy"])
    return
  end
  AcceptGroup()
  adherent:echo(L["Accepting invite from %s. They are %s :)"], sender, L[reason])
  local dialog = StaticPopup_FindVisible("PARTY_INVITE")
  if dialog then
    --StaticPopup_Hide("PARTY_INVITE")
    _G[dialog:GetName().."Button1"]:Click() -- would this taint staticpopup?
  end
end

function adherent:remoteDiscovery(name)
  local is_known = self.db.profile.adherents[name]
  if not is_known then
    self:ping(name)
  else
    self:pong(name)
  end
end

function adherent:updateKnown(name, version, action)
  local knownAdherents = self.db.profile.adherents
  if not knownAdherents[name] then
    knownAdherents[name] = true
    self:echo(L["Discovered <%s>"],name)
  end
  if version then
    knownAdherents[name] = version
  end
  if action and action == "-" then
    knownAdherents[name] = nil
    self:echo(L["Removing <%s> from known"],name)
  end
end

function adherent:checkPong(name)
  if not pongReceived[name] and self.db.profile.adherents[name] then
    self:updateKnown(name,nil,"-") -- remove them from known
  end
end

function adherent:ping(name)
  if not alreadyPinged[name] then
    local addonMsg = string.format("PING;%s",adherent._versionString)
    self:addonMessage(addonMsg,"WHISPER",name)
    if self.db.profile.adherents[name] then -- they had adherent at some point, do they still?
      self:ScheduleTimer("checkPong", 2, name)
    end
  end
  alreadyPinged[name] = true
end

function adherent:pong(name)
  if not alreadyPonged[name] then
    local addonMsg = string.format("PONG;%s",adherent._versionString)
    self:addonMessage(addonMsg,"WHISPER",name)
  end
  alreadyPonged[name] = true
end

function adherent:addonMessage(msg, distro, target)
  local prio = "BULK"
  if distro == "WHISPER" then
    prio = "NORMAL"
  end
  self:SendCommMessage(COMM_PREFIX,msg,distro,target,prio)
end

function adherent:OnCommReceived(prefix, msg, distro, sender)
  if not prefix == COMM_PREFIX then return end -- not our message
  local sender = Ambiguate(sender, "short")
  if sender == self._playerName then return end -- don't care for our own message
  self:updateKnown(sender)
  local who,what,data
  for name,action,chatType in string.gmatch(msg,"([^;]+);([^;]+);([^;]+)") do
    who = name
    what = action
    data = chatType
  end
  if (who) and (what) and (data) then
    if who == "VER" then
      self:updateKnown(sender,what)
      self:pong(sender)
      local out_of_date, version_type = self:parseVersion(self._versionString,what)
      if (out_of_date) and self._newVersionNotification == nil then
        self._newVersionNotification = true -- only inform once per session
        self:Print(string.format(L["New %s version available: |cff00ff00%s|r"],version_type,what))
        self:Print(string.format(L["Visit %s to update."],self._websiteString))
      end
    elseif who == "PING" then
      self:updateKnown(sender,what)
      self:pong(sender)
    elseif who == "PONG" then
      pongReceived[sender] = true
      self:updateKnown(sender,what)
    elseif who == "AFK" then
      self:updateKnown(sender)
      if self.db.char.echo then
        local status
        if data then
          status = data=="1" and L["went AFK"] or L["returned from AFK"]
          if status and what then
            self:debugPrint(format(L["%s %s at %s"],sender, status, what))
          end
        end
      end
    end
  end
end

-------------------------------------------
--// EVENTS
-------------------------------------------
function adherent:FRIENDLIST_UPDATE()
  if self._pendingFLU then self._pendingFLU = nil end
  if self:combat() then
    self._pendingFLU = true
    self:RegisterEvent("PLAYER_REGEN_ENABLED")
    return
  end
  local numFriends = C_FriendList.GetNumFriends()
  if numFriends <= 0 then return end
  local roster = self.db.char.friends
  for k,_ in pairs(roster) do
    roster[k] = false
  end
  local serverQuery = false
  for i=1, numFriends do
    local info = C_FriendList.GetFriendInfoByIndex(i)
    if info and info.name and not (info.name == _G.UNKNOWNOBJECT or info.name == "") then
      roster[info.name] = info.guid or true
    else -- request for new data
      serverQuery = true
    end
  end
  if serverQuery then
    C_FriendList.ShowFriends()
  end
end

function adherent:PLAYER_GUILD_UPDATE(event, ...)
  local unitid = ...
  if unitid and UnitIsUnit(unitid,"player") then
    if IsInGuild() then
      self._initdone = false
      self:OnEnable()
    end
  end
end

function adherent:GUILD_ROSTER_UPDATE()
  if self._pendingGRU then self._pendingGRU = nil end
  local incombat = self:combat()
  if (_G.GuildFrame and _G.GuildFrame:IsShown()) or incombat then
    if incombat then
      self._pendingGRU = true
      self:RegisterEvent("PLAYER_REGEN_ENABLED")
    end
    return
  end
  local guildname = GetGuildInfo("player")
  if guildname then
    self:deferredInit(guildname)
  end
  local roster = self.db.profile.guild
  for k,_ in pairs(roster) do
    roster[k] = false
  end
  for i=1, GetNumGuildMembers() do
    local name,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,guid = GetGuildRosterInfo(i)
    if name and not (name == _G.UNKNOWNOBJECT or name == "") then
      name = Ambiguate(name, "short") --"mail" = always name-realm, "short" = always just name
      roster[name] = guid or true
    end
  end
end

function adherent:CHAT_MSG_EVENT(event, ...)
  if self.db.char.suspend then return end
  local chatType = string.gsub(event, "CHAT_MSG_", "")
  local msg, sender, _, _, recipient, status,_, _, _, _, lineid, guid = ...
  sender = Ambiguate(sender,"short")
  if sender == self._playerName then return end
  local action
  if chatType == "TEXT_EMOTE" then
    action = self:parseEmote(msg, sender)
  else
    action = self:parseChat(msg)
  end
  if not action then return end
  self:Dispatch(action, sender, chatType)
end

function adherent:PARTY_INVITE_REQUEST(event, sender)
  if self.db.char.suspend then return end
  sender = Ambiguate(sender,"short")
  self:remoteDiscovery(sender)
  local is_blacklisted = self.db.char.groupjoin.blacklist[sender]
  local is_whitelisted = self.db.char.groupjoin.whitelist[sender]
  local is_guild = self.db.profile.guild[sender]
  local is_friend = self.db.char.friends[sender]
  if is_blacklisted then
    -- perhaps inform
    return
  end
  if is_whitelisted then
    acceptGroup("whitelist",sender)
    return
  end
  if self.db.char.groupjoin.all then
    acceptGroup("all",sender)
    return
  end
  if is_friend and self.db.char.groupjoin.friend then
    acceptGroup("friend",sender)
    return
  end
  if is_guild and self.db.char.groupjoin.guild then
    acceptGroup("guild",sender)
    return
  end
end

function adherent:PLAYER_FLAGS_CHANGED(event, unit)
  if IsInGroup() then
    local _, timestamp, addonMsg
    local afk = UnitIsAFK("player")
    if afk then
      if not self._playerAFK then -- non afk > afk
        _, timestamp = self:getServerTime("%a","%H:%M")
        addonMsg = string.format("AFK;%s;1",timestamp)
        self:addonMessage(addonMsg,"RAID")
      end
    else
      if self._playerAFK then -- afk > non afk
        _, timestamp = self:getServerTime("%a","%H:%M")
        addonMsg = string.format("AFK;%s;0",timestamp)
        self:addonMessage(addonMsg,"RAID")
      end
    end
    self._playerAFK = afk
  end
end

function adherent:PLAYER_REGEN_ENABLED()
  self:UnregisterEvent("PLAYER_REGEN_ENABLED")
  if self._pendingFLU then
    self:FRIENDLIST_UPDATE()
  end
  if self._pendingGRU then
    self:ScheduleTimer("GUILD_ROSTER_UPDATE", 2)
  end
end

function adherent:AUTOFOLLOW_BEGIN(event, who)
  self._lastBidder = nil
  self._lastLeader = nil
  self:UnregisterEvent("AUTOFOLLOW_BEGIN")
  self:RegisterEvent("AUTOFOLLOW_END")
  who = Ambiguate(who, "short")
  self:echo(_G.AUTOFOLLOWSTART, who)
  self:inform(who,L["follow"])
  self._lastLeader = who
end

function adherent:AUTOFOLLOW_END()
  self:UnregisterEvent("AUTOFOLLOW_END")
  if self._lastLeader then
    self:inform(self._lastLeader, L["followstop"])
  end
  self._lastLeader = nil
end

function adherent:UI_ERROR_MESSAGE(event, error_code, error_text)
  if self._lastBidder then
    local msg
    if error_code == LE_GAME_ERR_UNIT_NOT_FOUND then
      msg = L["ERR_UNIT_NOT_FOUND"]
    elseif error_code == LE_GAME_ERR_AUTOFOLLOW_TOO_FAR then
      msg = L["ERR_AUTOFOLLOW_TOO_FAR"]
    elseif error_code == LE_GAME_ERR_INVALID_FOLLOW_TARGET then
      msg = L["ERR_INVALID_FOLLOW_TARGET"]
    elseif error_code == LE_GAME_ERR_TOOBUSYTOFOLLOW then
      msg = L["ERR_TOOBUSYTOFOLLOW"]
    end
    if msg then
      self:inform(self._lastBidder,msg)
    end
  end
  self._lastBidder = nil
  self:UnregisterEvent("UI_ERROR_MESSAGE")
end

-------------------------------------------
--// UTILITY
-------------------------------------------
function adherent:num_round(i)
  return math.floor(i+0.5)
end

function adherent:table_count(t)
  local count = 0
  if type(t) == "table" then
    for k,v in pairs(t) do
      count = count+1
    end
  end
  return count
end

function adherent:table_val_array(t)
  local out = {}
  for k,v in pairs(t) do
    tinsert(out, v)
  end
  return out
end

function adherent:GetSlashCmdTarget(msg)
  msg = msg or ""
  local target, server
  target = gsub(msg, "(%s*)(.*[^%s]+)(%s*)", "%2", 1)
  if ( target == "" ) then
    if ( UnitIsPlayer("target") ) then
      target = "target"
    else
      target = nil
    end
  end
  if ( target and (target == "player" or target == "target" or
       strfind(target, "^party[1-4]") or
     strfind(target, "^raid[0-9]")) ) then
    target,server = UnitName(target)
  end
  return target,server
end

function adherent:validName(info,val)
  -- check characters >=2<=12
  -- check no spaces
  -- check no double apostrophes
  -- check no numbers
  local len = string.utf8len or string.len
  local err_msg = L["Not a valid player name: %s"]
  local name_len = len(val)
  if name_len == 0 then return true end -- let them exit the input if they clear the text
  local valid_len = name_len and name_len > 1 and name_len < 13
  if not valid_len then return format(err_msg,L["Length"]) end
  local _, num_blanks = val:gsub("%s","")
  if num_blanks > 0 then return format(err_msg,L["Spaces"]) end
  local _, num_doubleapos = val:gsub("\'\'","")
  if num_doubleapos > 0 then return format(err_msg,L["Double Apostrophes"]) end
  local _, num_nums = val:gsub("%d","")
  if num_nums > 0 then return format(err_msg,L["Numbers"]) end
  return true
end

function adherent:Capitalize(word)
  return (string.gsub(word,"^[%c%s]*([^%c%s%p%d])([^%c%s%p%d]*)",function(head,tail)
    return string.format("%s%s",string.upper(head),string.lower(tail))
    end))
end

function adherent:getServerTime(date_fmt, time_fmt, epoch)
  local epoch = epoch or GetServerTime()
  local date_fmt = date_fmt or "%b-%d" -- Mon-dd, alt example: "%Y-%m-%d" > YYYY-MM-DD
  local time_fmt = time_fmt or "%H:%M:%S" -- HH:mm:SS
  local d = date(date_fmt,epoch)
  local t = date(time_fmt,epoch)
  local timestamp = string.format("%s %s",d,t)
  return tostring(epoch), timestamp
end

_G[addonName] = adherent
