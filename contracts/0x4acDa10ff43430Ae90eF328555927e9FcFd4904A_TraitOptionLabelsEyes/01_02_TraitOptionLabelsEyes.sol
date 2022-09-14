// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "../trait_options/TraitOptionsEyes.sol";

library TraitOptionLabelsEyes {
  string constant ANNOYED_BLUE_EYES = "Annoyed Blue Eyes";
  string constant ANNOYED_BROWN_EYES = "Annoyed Brown Eyes";
  string constant ANNOYED_GREEN_EYES = "Annoyed Green Eyes";
  string constant BEADY_EYES = "Beady Eyes";
  string constant BEADY_RED_EYES = "Beady Red Eyes";
  string constant BORED_BLUE_EYES = "Bored Blue Eyes";
  string constant BORED_BROWN_EYES = "Bored Brown Eyes";
  string constant BORED_GREEN_EYES = "Bored Green Eyes";
  string constant DILATED_BLUE_EYES = "Dilated Blue Eyes";
  string constant DILATED_BROWN_EYES = "Dilated Brown Eyes";
  string constant DILATED_GREEN_EYES = "Dilated Green Eyes";
  string constant NEUTRAL_BLUE_EYES = "Neutral Blue Eyes";
  string constant NEUTRAL_BROWN_EYES = "Neutral Brown Eyes";
  string constant NEUTRAL_GREEN_EYES = "Neutral Green Eyes";
  string constant SQUARE_BLUE_EYES = "Square Blue Eyes";
  string constant SQUARE_BROWN_EYES = "Square Brown Eyes";
  string constant SQUARE_GREEN_EYES = "Square Green Eyes";
  string constant SURPRISED_BLUE_EYES = "Surprised Blue Eyes";
  string constant SURPRISED_BROWN_EYES = "Surprised Brown Eyes";
  string constant SURPRISED_GREEN_EYES = "Surprised Green Eyes";

  function getLabel(uint8 optionNum) public pure returns (string memory) {
    if (optionNum == TraitOptionsEyes.ANNOYED_BLUE_EYES) {
      return ANNOYED_BLUE_EYES;
    } else if (optionNum == TraitOptionsEyes.ANNOYED_BROWN_EYES) {
      return ANNOYED_BROWN_EYES;
    } else if (optionNum == TraitOptionsEyes.ANNOYED_GREEN_EYES) {
      return ANNOYED_GREEN_EYES;
    } else if (optionNum == TraitOptionsEyes.BEADY_EYES) {
      return BEADY_EYES;
    } else if (optionNum == TraitOptionsEyes.BEADY_RED_EYES) {
      return BEADY_RED_EYES;
    } else if (optionNum == TraitOptionsEyes.BORED_BLUE_EYES) {
      return BORED_BLUE_EYES;
    } else if (optionNum == TraitOptionsEyes.BORED_BROWN_EYES) {
      return BORED_BROWN_EYES;
    } else if (optionNum == TraitOptionsEyes.BORED_GREEN_EYES) {
      return BORED_GREEN_EYES;
    } else if (optionNum == TraitOptionsEyes.DILATED_BLUE_EYES) {
      return DILATED_BLUE_EYES;
    } else if (optionNum == TraitOptionsEyes.DILATED_BROWN_EYES) {
      return DILATED_BROWN_EYES;
    } else if (optionNum == TraitOptionsEyes.DILATED_GREEN_EYES) {
      return DILATED_GREEN_EYES;
    } else if (optionNum == TraitOptionsEyes.NEUTRAL_BLUE_EYES) {
      return NEUTRAL_BLUE_EYES;
    } else if (optionNum == TraitOptionsEyes.NEUTRAL_BROWN_EYES) {
      return NEUTRAL_BROWN_EYES;
    } else if (optionNum == TraitOptionsEyes.NEUTRAL_GREEN_EYES) {
      return NEUTRAL_GREEN_EYES;
    } else if (optionNum == TraitOptionsEyes.SQUARE_BLUE_EYES) {
      return SQUARE_BLUE_EYES;
    } else if (optionNum == TraitOptionsEyes.SQUARE_BROWN_EYES) {
      return SQUARE_BROWN_EYES;
    } else if (optionNum == TraitOptionsEyes.SQUARE_GREEN_EYES) {
      return SQUARE_GREEN_EYES;
    } else if (optionNum == TraitOptionsEyes.SURPRISED_BLUE_EYES) {
      return SURPRISED_BLUE_EYES;
    } else if (optionNum == TraitOptionsEyes.SURPRISED_BROWN_EYES) {
      return SURPRISED_BROWN_EYES;
    } else if (optionNum == TraitOptionsEyes.SURPRISED_GREEN_EYES) {
      return SURPRISED_GREEN_EYES;
    }
    return BORED_BLUE_EYES;
  }
}