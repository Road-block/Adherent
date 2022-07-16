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
  L["%s will not interrupt Trade/Mail/Auction/Bank/Professions/Queues"] = true
  L["Not in Combat"] = true
  L["%s will not automate when you are in Combat"] = true
  L["Not in Instances"] = true
  L["%s will not automate when you are in a PvE Instance"] = true
  L["Can't comply due to \'%s\' option"] = true
  L["Echo %s actions"] = true
  L["Print %s actions to your chatframe"] = true
  L["Blizzard Options"] = true
  L["Left Click"] = true
  L["Right Click"] = true
  L["Defaults"] = true
  L["|T357854:16|tWarning!|T357854:16|t\nThis action will wipe ALL addon data."] = true
  L["Auto follow Options"] = true
  L["Auto group"] = true
  L["Auto group Join Options"] = true
  L["Group Invite"] = true
  L["Auto group Invite Options"] = true
  L["Suspend %s"] = true
  L["Suspend all auto accept actions."] = true
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
  L["%s will listen to"] = true
  L["Only Custom"] = true
  L["Only react to |cffffff00custom|r keywords (ignore |cffdcdcdcdefaults|r)"] = true
  L["Auto accept Group Invites from"] = true
  L["Player Tooltip Hint"] = true
  L["Indicate known %s in player tooltips with an icon after their Name|T%s:15|t"] = true
  L["Inform Initiator"] = true
  L["Send a tell to action initiator when accepting or declining"] = true
  L["Quick Settings"] = true
  L["[Suspended]"] = true
  L["[Enabled]"] = true
  L["Discovered <%s>"] = true
  L["Removing <%s> from known"] = true
  L["Known"] = true
  L["Print discovered Adherents.\nUse a partial name to limit results"] = true
  L["Greet"] = true
  L["Send a backchannel greeting to a player to discover if they have an Adherent"] = true
  L["Not a valid player name: %s"] = true
  L["Length"] = true
  L["Spaces"] = true
  L["Numbers"] = true
  L["Double Apostrophes"] = true
  L["went AFK"] = true
  L["returned from AFK"] = true
  L["%s %s at %s"] = true
  L["<%s> says %s"] = true
  L["Starter only"] = true
  L["Stop Follow"] = true
  L["Only stop if request comes from follow Starter"] = true
  L["Request to stop following by %s"] = true
  L["Accepting invite from %s. They are %s :)"] = true
  L["Sending invite to %s."] = true
  L["Automatically convert to raid when party full."] = true
  L["Raid Convert"] = true
  L["whitelist"] = "trusted"
  L["friend"] = "a friend"
  L["guild"] = "a guildie"
  L["follow"] = "I am following you. Lead the way :)"
  L["followstop"] = "I am no longer following :||"
  L["ERR_UNIT_NOT_FOUND"] = "Can't follow you. Not visible."
  L["ERR_AUTOFOLLOW_TOO_FAR"] = "Can't follow you until you come closer."
  L["ERR_INVALID_FOLLOW_TARGET"] = "Can't follow that unit."
  L["ERR_TOOBUSYTOFOLLOW"] = "Can't follow. Too Busy."
  L.FOLLOWSTOP_DETAIL = [[Normally any category of player that's allowed to start a follow can also stop one.
Check this if you want only the specific player that started a follow to be able to stop it.]]
  L.DEFAULT_KEYWORDS = [[• Start Follow: |cffdcdcdc!fme|r%s
• Stop Following: |cffdcdcdc!fno|r%s]]
  L.DEFAULT_EMOTES = [[• Start Follow: |cffff8c00/%sme|r or |cffff8c00/%s|r
• Stop Following: |cffff8c00/%s|r or |cffff8c00/%s|r]]
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
