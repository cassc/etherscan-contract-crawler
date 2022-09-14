// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "../trait_options/TraitOptionsLocale.sol";

library TraitOptionLabelsLocale {
  string constant NORTH_AMERICAN = "North America";
  string constant SOUTH_AMERICAN = "South America";
  string constant ASIAN = "Asia";
  string constant EUROPEAN = "Europe";

  function getLabel(uint8 optionNum) public pure returns (string memory) {
    if (optionNum == TraitOptionsLocale.NORTH_AMERICAN) {
      return NORTH_AMERICAN;
    } else if (optionNum == TraitOptionsLocale.SOUTH_AMERICAN) {
      return SOUTH_AMERICAN;
    } else if (optionNum == TraitOptionsLocale.ASIAN) {
      return ASIAN;
    } else if (optionNum == TraitOptionsLocale.EUROPEAN) {
      return EUROPEAN;
    }
    return NORTH_AMERICAN;
  }
}