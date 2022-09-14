// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "../trait_options/TraitOptionsBelly.sol";

library TraitOptionLabelsBelly {
  string constant LARGE = "Large";
  string constant SMALL = "Small";

  function getLabel(uint8 optionNum) public pure returns (string memory) {
    if (optionNum == TraitOptionsBelly.LARGE) {
      return LARGE;
    } else if (optionNum == TraitOptionsBelly.SMALL) {
      return SMALL;
    }
    return LARGE;
  }
}