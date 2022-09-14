// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "../trait_options/TraitOptionsSpecies.sol";

library TraitOptionLabelsSpecies {
  string constant BLACK = "Black Bear";
  string constant POLAR = "Polar Bear";
  string constant PANDA = "Panda Bear";
  string constant REVERSE_PANDA = "Reverse Panda Bear";
  string constant GOLD_PANDA = "Gold Panda";

  function getLabel(uint8 optionNum) public pure returns (string memory) {
    if (optionNum == TraitOptionsSpecies.BLACK) {
      return BLACK;
    } else if (optionNum == TraitOptionsSpecies.POLAR) {
      return POLAR;
    } else if (optionNum == TraitOptionsSpecies.PANDA) {
      return PANDA;
    } else if (optionNum == TraitOptionsSpecies.REVERSE_PANDA) {
      return REVERSE_PANDA;
    } else if (optionNum == TraitOptionsSpecies.GOLD_PANDA) {
      return GOLD_PANDA;
    }
    return BLACK;
  }
}