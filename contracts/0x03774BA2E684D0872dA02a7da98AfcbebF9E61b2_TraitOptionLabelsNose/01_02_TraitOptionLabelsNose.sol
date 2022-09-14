// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "../trait_options/TraitOptionsNose.sol";

library TraitOptionLabelsNose {
  string constant BLACK_NOSTRILS_SNIFFER = "Black Nostrils Sniffer";
  string constant BLACK_SNIFFER = "Small Black Sniffer";
  string constant BLUE_NOSTRILS_SNIFFER = "Blue Nostrils Sniffer";
  string constant PINK_NOSTRILS_SNIFFER = "Pink Nostrils Sniffer";
  string constant RUNNY_BLACK_NOSE = "Runny Black Nose";
  string constant SMALL_BLUE_SNIFFER = "Small Blue Sniffer";
  string constant SMALL_PINK_NOSE = "Small Pink Sniffer";
  string constant WIDE_BLACK_SNIFFER = "Wide Black Sniffer";
  string constant WIDE_BLUE_SNIFFER = "Wide Blue Sniffer";
  string constant WIDE_PINK_SNIFFER = "Wide Pink Sniffer";

  function getLabel(uint8 optionNum) public pure returns (string memory) {
    if (optionNum == TraitOptionsNose.BLACK_NOSTRILS_SNIFFER) {
      return BLACK_NOSTRILS_SNIFFER;
    } else if (optionNum == TraitOptionsNose.BLACK_SNIFFER) {
      return BLACK_SNIFFER;
    } else if (optionNum == TraitOptionsNose.BLUE_NOSTRILS_SNIFFER) {
      return BLUE_NOSTRILS_SNIFFER;
    } else if (optionNum == TraitOptionsNose.PINK_NOSTRILS_SNIFFER) {
      return PINK_NOSTRILS_SNIFFER;
    } else if (optionNum == TraitOptionsNose.RUNNY_BLACK_NOSE) {
      return RUNNY_BLACK_NOSE;
    } else if (optionNum == TraitOptionsNose.SMALL_BLUE_SNIFFER) {
      return SMALL_BLUE_SNIFFER;
    } else if (optionNum == TraitOptionsNose.SMALL_PINK_NOSE) {
      return SMALL_PINK_NOSE;
    } else if (optionNum == TraitOptionsNose.WIDE_BLACK_SNIFFER) {
      return WIDE_BLACK_SNIFFER;
    } else if (optionNum == TraitOptionsNose.WIDE_BLUE_SNIFFER) {
      return WIDE_BLUE_SNIFFER;
    } else if (optionNum == TraitOptionsNose.WIDE_PINK_SNIFFER) {
      return WIDE_PINK_SNIFFER;
    }
    return BLACK_NOSTRILS_SNIFFER;
  }
}