// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "../trait_options/TraitOptionsBackground.sol";

library TraitOptionLabelsBackground {
  string constant RED = "Red";
  string constant BLUE = "Blue";
  string constant GREEN = "Green";
  string constant YELLOW = "Yellow";

  function getLabel(uint8 optionNum) public pure returns (string memory) {
    if (optionNum == TraitOptionsBackground.RED) {
      return RED;
    } else if (optionNum == TraitOptionsBackground.BLUE) {
      return BLUE;
    } else if (optionNum == TraitOptionsBackground.GREEN) {
      return GREEN;
    } else if (optionNum == TraitOptionsBackground.YELLOW) {
      return YELLOW;
    }
    return RED;
  }
}