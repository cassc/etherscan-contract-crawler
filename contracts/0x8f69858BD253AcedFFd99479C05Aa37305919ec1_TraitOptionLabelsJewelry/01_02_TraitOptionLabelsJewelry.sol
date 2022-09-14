// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "../trait_options/TraitOptionsJewelry.sol";

library TraitOptionLabelsJewelry {
  string constant BLUE_BRACELET = "Blue Bracelet";
  string constant BLUE_SPORTS_WATCH = "Blue Sports Watch";
  string constant DECENTRALIZED_ETHEREUM_STAKING_PROTOCOL_MEDALLION =
    "Rocket Pool Medallion";
  string constant DOUBLE_GOLD_CHAINS = "Double Gold Chains";
  string constant DOUBLE_SILVER_CHAINS = "Double Silver Chains";
  string constant GOLD_CHAIN_WITH_MEDALLION = "Gold Chain with Medallion";
  string constant GOLD_CHAIN_WITH_RED_RUBY = "Gold Chain with Red Ruby";
  string constant GOLD_CHAIN = "Gold Chain";
  // string constant GOLD_STUD_EARRINGS = "Gold Stud Earrings";
  string constant GOLD_WATCH_ON_LEFT_WRIST = "Gold Watch on Left Wrist";
  string constant LEFT_HAND_GOLD_RINGS = "Left Hand Gold Rings";
  string constant LEFT_HAND_SILVER_RINGS = "Left Hand Silver Rings";
  string constant RED_BRACELET = "Red Bracelet";
  string constant RED_SPORTS_WATCH = "Red Sports Watch";
  string constant SILVER_CHAIN_WITH_MEDALLION = "Silver Chain with Medallion";
  string constant SILVER_CHAIN_WITH_RED_RUBY = "Silver Chain with Red Ruby";
  string constant SILVER_CHAIN = "Silver Chain";
  // string constant SILVER_STUD_EARRINGS = "Silver Stud Earrings";
  string constant NONE = "None";

  function getLabel(uint8 optionNum) public pure returns (string memory) {
    if (optionNum == TraitOptionsJewelry.BLUE_BRACELET) {
      return BLUE_BRACELET;
    } else if (optionNum == TraitOptionsJewelry.BLUE_SPORTS_WATCH) {
      return BLUE_SPORTS_WATCH;
    } else if (
      optionNum ==
      TraitOptionsJewelry.DECENTRALIZED_ETHEREUM_STAKING_PROTOCOL_MEDALLION
    ) {
      return DECENTRALIZED_ETHEREUM_STAKING_PROTOCOL_MEDALLION;
    } else if (optionNum == TraitOptionsJewelry.DOUBLE_GOLD_CHAINS) {
      return DOUBLE_GOLD_CHAINS;
    } else if (optionNum == TraitOptionsJewelry.DOUBLE_SILVER_CHAINS) {
      return DOUBLE_SILVER_CHAINS;
    } else if (optionNum == TraitOptionsJewelry.GOLD_CHAIN_WITH_MEDALLION) {
      return GOLD_CHAIN_WITH_MEDALLION;
    } else if (optionNum == TraitOptionsJewelry.GOLD_CHAIN_WITH_RED_RUBY) {
      return GOLD_CHAIN_WITH_RED_RUBY;
    } else if (optionNum == TraitOptionsJewelry.GOLD_CHAIN) {
      return GOLD_CHAIN;
    } else if (optionNum == TraitOptionsJewelry.GOLD_WATCH_ON_LEFT_WRIST) {
      return GOLD_WATCH_ON_LEFT_WRIST;
    } else if (optionNum == TraitOptionsJewelry.LEFT_HAND_GOLD_RINGS) {
      return LEFT_HAND_GOLD_RINGS;
    } else if (optionNum == TraitOptionsJewelry.LEFT_HAND_SILVER_RINGS) {
      return LEFT_HAND_SILVER_RINGS;
    } else if (optionNum == TraitOptionsJewelry.RED_BRACELET) {
      return RED_BRACELET;
    } else if (optionNum == TraitOptionsJewelry.RED_SPORTS_WATCH) {
      return RED_SPORTS_WATCH;
    } else if (optionNum == TraitOptionsJewelry.SILVER_CHAIN_WITH_MEDALLION) {
      return SILVER_CHAIN_WITH_MEDALLION;
    } else if (optionNum == TraitOptionsJewelry.SILVER_CHAIN_WITH_RED_RUBY) {
      return SILVER_CHAIN_WITH_RED_RUBY;
    } else if (optionNum == TraitOptionsJewelry.SILVER_CHAIN) {
      return SILVER_CHAIN;
    } else if (optionNum == TraitOptionsJewelry.NONE) {
      return NONE;
    }
    return NONE;
  }
}