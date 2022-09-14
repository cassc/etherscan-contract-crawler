// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "../trait_options/TraitOptionsMouth.sol";

library TraitOptionLabelsMouth {
  string constant ANXIOUS = "Anxious";
  string constant BABY_TOOTH_SMILE = "Baby Tooth Smile";
  string constant BLUE_LIPSTICK = "Blue Lipstick";
  string constant FULL_MOUTH = "Full Mouth";
  string constant MISSING_BOTTOM_TOOTH = "Missing Bottom Tooth";
  string constant NERVOUS_MOUTH = "Nervous";
  string constant OPEN_MOUTH = "Open";
  string constant PINK_LIPSTICK = "Pink Lipstick";
  string constant RED_LIPSTICK = "Red Lipstick";
  string constant SAD_FROWN = "Sad Frown";
  string constant SMILE_WITH_BUCK_TEETH = "Smile with Buck Teeth";
  string constant SMILE_WITH_PIPE = "Smile with Pipe";
  string constant SMILE = "Smile";
  string constant SMIRK = "Smirk";
  string constant TINY_FROWN = "Tiny Frown";
  string constant TINY_SMILE = "Tiny Smile";
  string constant TONGUE_OUT = "Tongue Out";
  string constant TOOTHY_SMILE = "Toothy Smile";

  function getLabel(uint8 optionNum) public pure returns (string memory) {
    if (optionNum == TraitOptionsMouth.ANXIOUS) {
      return ANXIOUS;
    } else if (optionNum == TraitOptionsMouth.BABY_TOOTH_SMILE) {
      return BABY_TOOTH_SMILE;
    } else if (optionNum == TraitOptionsMouth.BLUE_LIPSTICK) {
      return BLUE_LIPSTICK;
    } else if (optionNum == TraitOptionsMouth.FULL_MOUTH) {
      return FULL_MOUTH;
    } else if (optionNum == TraitOptionsMouth.MISSING_BOTTOM_TOOTH) {
      return MISSING_BOTTOM_TOOTH;
    } else if (optionNum == TraitOptionsMouth.NERVOUS_MOUTH) {
      return NERVOUS_MOUTH;
    } else if (optionNum == TraitOptionsMouth.OPEN_MOUTH) {
      return OPEN_MOUTH;
    } else if (optionNum == TraitOptionsMouth.PINK_LIPSTICK) {
      return PINK_LIPSTICK;
    } else if (optionNum == TraitOptionsMouth.RED_LIPSTICK) {
      return RED_LIPSTICK;
    } else if (optionNum == TraitOptionsMouth.SAD_FROWN) {
      return SAD_FROWN;
    } else if (optionNum == TraitOptionsMouth.SMILE_WITH_BUCK_TEETH) {
      return SMILE_WITH_BUCK_TEETH;
    } else if (optionNum == TraitOptionsMouth.SMILE_WITH_PIPE) {
      return SMILE_WITH_PIPE;
    } else if (optionNum == TraitOptionsMouth.SMILE) {
      return SMILE;
    } else if (optionNum == TraitOptionsMouth.SMIRK) {
      return SMIRK;
    } else if (optionNum == TraitOptionsMouth.TINY_FROWN) {
      return TINY_FROWN;
    } else if (optionNum == TraitOptionsMouth.TINY_SMILE) {
      return TINY_SMILE;
    } else if (optionNum == TraitOptionsMouth.TONGUE_OUT) {
      return TONGUE_OUT;
    } else if (optionNum == TraitOptionsMouth.TOOTHY_SMILE) {
      return TOOTHY_SMILE;
    }
    return SMILE;
  }
}