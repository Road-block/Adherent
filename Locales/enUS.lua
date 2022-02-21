local addonName, adherent = ...
local L = LibStub("AceLocale-3.0"):NewLocale(addonName, "enUS", true)
if not L then return end
  --["Term"] = true -- Example
  -- function
  L[EMOTE163_TOKEN] = "%s motions for you to follow."
  L[EMOTE7_TOKEN]   = "%s beckons you over."
  L[EMOTE164_TOKEN] = "%s asks you to wait."
  L[EMOTE130_TOKEN] = "%s shoos you away. Be gone pest!"
  L[EMOTE382_TOKEN] = "%s puts %s arm around your shoulder." -- male and female versions exist
  L[EMOTE112_TOKEN] = "%s cuddles up against you."
  -- UI
  L["Toggle"] = true
  L["Hide from Minimap"] = true
  L["Hide addon Minimap Button."] = true
  L["Not when busy"] = true
  L["%s will not interrupt Trade/Mail/Auction/Bank/Professions"] = true
  L["Not in Combat"] = true
  L["%s will not automate when you are in Combat"] = true
  L["Not in Instances"] = true
  L["%s will not automate when you are in an Instance"] = true
  L["<%s>:\'%s\' option prevents me from obliging."] = true
  L["Echo %s actions"] = true
  L["Print %s actions to your chatframe"] = true
  L["Blizzard Options"] = true
  L["Left Click"] = true
  L["Right Click"] = true
  L["Defaults"] = true
  L["|cffff0000Warning!|r\nThis action will wipe all user options and revert to defaults."] = true
  L["Auto follow Options"] = true
  L["Auto group"] = true
  L["Auto group Join Options"] = true
  L["Group Invite"] = true
  L["Auto group Invite Options"] = true
  L["Suspend %s"] = true
  L["Suspend all auto accept actions."] = true
  L["|cffff7f00Right Click|r | %s."] = true
  L["Who?"] = true
  L["Who can put you on follow."] = true
  L["Anyone"] = true
  L["How?"] = true
  L["Which channels should %s monitor?"] = true
  L["React to Emotes."] = true
  L["Add to Blacklist"] = true
  L["Names of players you never want to permit control of %s.\nSupercedes other options."] = true
  L["Remove from Blacklist"] = true
  L["Remove a player from Blacklist."] = true
  L["Copy from another Blacklist"] = true
  L["Copies the contents from another Blacklist\n|cffff0000Warning|r: Current contents will be overwritten!"] = true
  L["Add to Whitelist"] = true
  L["Names of players you always want to permit control.\nSupercedes other options except Blacklist."] = true
  L["Remove from Whitelist"] = true
  L["Remove a player from Whitelist."] = true
  L["Copy from another Whitelist"] = true
  L["Copies the contents from another Whitelist\n|cffff0000Warning|r: Current contents will be overwritten!"] = true
  L["Follow Keywords"] = true
  L["Stop Keywords"] = true
  L["Send Group Invite Keywords"] = true
  L["Keywords in Chat"] = true
  L["Save custom keywords for auto Follow."] = true
  L["Save custom keywords for stopping Follow."] = true
  L["Save custom keywords for auto Group Invite."] = true
  L["Remove Keyword"] = true
  L["Remove keywords from Custom Keywords"] = true
  L["Keywords monitored by %s"] = true
  L["Who can command %s?"] = true
  L["%s will listen to.."] = true
  L["Only Custom"] = true
  L["Only react to |cffffff00custom|r keywords (ignore |cffdcdcdcdefaults|r)"] = true
  L["Auto accept Group Invites from.."] = true
  L["Player Tooltip Hint"] = true
  L["Indicate other %s Users with icon after Player names"] = true
  L["Quick Settings"] = true
  L["[Suspended]"] = true
  L.DEFAULT_KEYWORDS = [[• Start Follow: |cffdcdcdc!fme|r%s
• Stop Following: |cffdcdcdc!fno|r%s
]]
  L.DEFAULT_EMOTES = [[• Start Follow: |cffff8c00/%sme|r or |cffff8c00/%s|r
• Stop Following: |cffff8c00/%s|r or |cffff8c00/%s|r
]]
  L.USAGE = [[|cff00ff00Adherent|r
Define rules for auto-accepting requests for Follow, Group Join or Group Invite.

• Blacklist or Whitelist players. Supercedes other rules.
• Select which chat the addon will react to, define optional custom keywords.
• Select guild, friend or group affiliation for auto-accepting requests.
• Each category has its own options, can be copied to another category.

|cffffff00Adherent can be quickly suspended from minimap/LDB or command-line.|r]]
  L.DEFAULT_KEYWORDS_GROUP = [[• Send Invite: |cffdcdcdc!invme|r%s]]
  L.DEFAULT_EMOTES_GROUP = [[• Send Invite: |cffff8c00/%s|r or |cffff8c00/%s|r]]

adherent.L = L
