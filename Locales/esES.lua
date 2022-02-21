local addonName, adherent = ...
local L = LibStub("AceLocale-3.0"):NewLocale(addonName, "esES")
if not L then return end
  -- function
  L[EMOTE163_TOKEN] = "%s te indica que no te separes."
  L[EMOTE7_TOKEN]   = "%s te hace señas."
  L[EMOTE164_TOKEN] = "%s te pide que esperes."
  L[EMOTE130_TOKEN] = "%s te espanta. ¡Fuera, bicho!"
  L[EMOTE382_TOKEN] = "%s te pasa el brazo por los hombros." -- spanish male and female versions same?
  L[EMOTE112_TOKEN] = "%s se acurruca contra ti."

  adherent.L = L
