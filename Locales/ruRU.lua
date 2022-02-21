local addonName, adherent = ...
local L = LibStub("AceLocale-3.0"):NewLocale(addonName, "ruRU")
if not L then return end
  -- function
  L[EMOTE163_TOKEN] = "%s жестом велит вам следовать за собой."
  L[EMOTE7_TOKEN]   = "%s жестом подзывает вас."
  L[EMOTE164_TOKEN] = "%s просит вас подождать."
  L[EMOTE130_TOKEN] = "%s отгоняет вас. Сгинь, зараза!"
  L[EMOTE382_TOKEN] = "%s обнимает вас за плечи." -- russian male and female versions same?
  L[EMOTE112_TOKEN] = "%s прижимается к вам."

  adherent.L = L
