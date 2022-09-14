// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "../trait_options/TraitOptionsFaceAccessory.sol";

library TraitOptionLabelsFaceAccessory {
  string constant BLACK_NINJA_MASK = "Black Ninja Mask";
  string constant BLACK_SWIMMING_GOGGLES_WITH_BLUE_SNORKEL =
    "Black Swimming Goggles with Blue Snorkel";
  string constant BLUE_FRAMED_GLASSES = "Blue Framed Glasses";
  string constant BLUE_MEDICAL_MASK = "Blue Medical Mask";
  string constant BLUE_NINJA_MASK = "Blue Ninja Mask";
  string constant BLUE_STRAIGHT_BOTTOM_FRAMED_GLASSES =
    "Blue Straight-Bottom Framed Glasses";
  string constant BLUE_VERBS_GLASSES = "Blue Nouns Glasses";
  string constant BLUE_AND_BLACK_CHECKERED_BANDANA =
    "Blue and Black Checkered Bandana";
  string constant BROWN_FRAMED_GLASSES = "Brown Framed Glasses";
  string constant CANDY_CANE = "Candy Cane";
  string constant GOLD_FRAMED_MONOCLE = "Gold Framed Monocle";
  string constant GRAY_BEARD = "Gray Beard";
  string constant NONE = "None";
  string constant RED_FRAMED_GLASSES = "Red Framed Glasses";
  string constant RED_MEDICAL_MASK = "Red Medical Mask";
  string constant RED_NINJA_MASK = "Red Ninja Mask";
  string constant RED_STRAIGHT_BOTTOM_FRAMED_GLASSES =
    "Red Straight-Bottom Framed Glasses";
  string constant RED_VERBS_GLASSES = "Red Nouns Glasses";
  string constant RED_AND_WHITE_CHECKERED_BANDANA =
    "Red and White Checkered Bandana";
  string constant WHITE_NINJA_MASK = "White Ninja Mask";
  string constant WHITE_SWIMMING_GOGGLES_WITH_RED_SNORKEL =
    "White Swimming Goggles with Red Snorkel";
  string constant HEAD_CONE = "Head Cone";
  // string constant CLOWN_FACE_PAINT = "Clown Face Paint";
  string constant DRIPPING_HONEY = "Dripping Honey";

  // moved from jewelry
  // string constant GOLD_STUD_EARRINGS = "";
  // string constant SILVER_STUD_EARRINGS = "";

  function getLabel(uint8 optionNum) public pure returns (string memory) {
    if (optionNum == TraitOptionsFaceAccessory.BLACK_NINJA_MASK) {
      return BLACK_NINJA_MASK;
    } else if (
      optionNum ==
      TraitOptionsFaceAccessory.BLACK_SWIMMING_GOGGLES_WITH_BLUE_SNORKEL
    ) {
      return BLACK_SWIMMING_GOGGLES_WITH_BLUE_SNORKEL;
    } else if (optionNum == TraitOptionsFaceAccessory.BLUE_FRAMED_GLASSES) {
      return BLUE_FRAMED_GLASSES;
    } else if (optionNum == TraitOptionsFaceAccessory.BLUE_MEDICAL_MASK) {
      return BLUE_MEDICAL_MASK;
    } else if (optionNum == TraitOptionsFaceAccessory.BLUE_NINJA_MASK) {
      return BLUE_NINJA_MASK;
    } else if (
      optionNum == TraitOptionsFaceAccessory.BLUE_STRAIGHT_BOTTOM_FRAMED_GLASSES
    ) {
      return BLUE_STRAIGHT_BOTTOM_FRAMED_GLASSES;
    } else if (optionNum == TraitOptionsFaceAccessory.BLUE_VERBS_GLASSES) {
      return BLUE_VERBS_GLASSES;
    } else if (
      optionNum == TraitOptionsFaceAccessory.BLUE_AND_BLACK_CHECKERED_BANDANA
    ) {
      return BLUE_AND_BLACK_CHECKERED_BANDANA;
    } else if (optionNum == TraitOptionsFaceAccessory.BROWN_FRAMED_GLASSES) {
      return BROWN_FRAMED_GLASSES;
    } else if (optionNum == TraitOptionsFaceAccessory.CANDY_CANE) {
      return CANDY_CANE;
    } else if (optionNum == TraitOptionsFaceAccessory.GOLD_FRAMED_MONOCLE) {
      return GOLD_FRAMED_MONOCLE;
    } else if (optionNum == TraitOptionsFaceAccessory.GRAY_BEARD) {
      return GRAY_BEARD;
    } else if (optionNum == TraitOptionsFaceAccessory.NONE) {
      return NONE;
    } else if (optionNum == TraitOptionsFaceAccessory.RED_FRAMED_GLASSES) {
      return RED_FRAMED_GLASSES;
    } else if (optionNum == TraitOptionsFaceAccessory.RED_MEDICAL_MASK) {
      return RED_MEDICAL_MASK;
    } else if (optionNum == TraitOptionsFaceAccessory.RED_NINJA_MASK) {
      return RED_NINJA_MASK;
    } else if (
      optionNum == TraitOptionsFaceAccessory.RED_STRAIGHT_BOTTOM_FRAMED_GLASSES
    ) {
      return RED_STRAIGHT_BOTTOM_FRAMED_GLASSES;
    } else if (optionNum == TraitOptionsFaceAccessory.RED_VERBS_GLASSES) {
      return RED_VERBS_GLASSES;
    } else if (
      optionNum == TraitOptionsFaceAccessory.RED_AND_WHITE_CHECKERED_BANDANA
    ) {
      return RED_AND_WHITE_CHECKERED_BANDANA;
    } else if (optionNum == TraitOptionsFaceAccessory.WHITE_NINJA_MASK) {
      return WHITE_NINJA_MASK;
    } else if (
      optionNum ==
      TraitOptionsFaceAccessory.WHITE_SWIMMING_GOGGLES_WITH_RED_SNORKEL
    ) {
      return WHITE_SWIMMING_GOGGLES_WITH_RED_SNORKEL;
    } else if (optionNum == TraitOptionsFaceAccessory.HEAD_CONE) {
      return HEAD_CONE;
    } else if (optionNum == TraitOptionsFaceAccessory.DRIPPING_HONEY) {
      return DRIPPING_HONEY;
    }
    return NONE;
  }
}