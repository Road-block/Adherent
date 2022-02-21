local addonName, adherent = ...
local L = LibStub("AceLocale-3.0"):NewLocale(addonName, "deDE")
if not L then return end
  -- function
  L[EMOTE163_TOKEN] = "%s gibt Euch ein Zeichen zu folgen."
  L[EMOTE7_TOKEN]   = "%s winkt Euch herüber."
  L[EMOTE164_TOKEN] = "%s bittet Euch zu warten."
  L[EMOTE130_TOKEN] = "%s verscheucht Euch. Hinfort, nervige Pest!"
  L[EMOTE382_TOKEN] = "%s legt einen Arm um Eure Schultern." -- german male and female versions same?
  L[EMOTE112_TOKEN] = "%s kuschelt sich an Euch."

  adherent.L = L
