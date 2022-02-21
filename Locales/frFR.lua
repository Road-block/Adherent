local addonName, adherent = ...
local L = LibStub("AceLocale-3.0"):NewLocale(addonName, "frFR")
if not L then return end
  -- function
  L[EMOTE163_TOKEN] = "%s vous fait signe de suivre."
  L[EMOTE7_TOKEN]   = "%s vous fait signe d'approcher."
  L[EMOTE164_TOKEN] = "%s vous demande d'attendre."
  L[EMOTE130_TOKEN] = "%s vous chasse. Du vent, sale teigne!"
  L[EMOTE382_TOKEN] = "%s met son bras autour de votre épaule." -- french male and female versions same?
  L[EMOTE112_TOKEN] = "%s se pelotonne contre vous."

  adherent.L = L
