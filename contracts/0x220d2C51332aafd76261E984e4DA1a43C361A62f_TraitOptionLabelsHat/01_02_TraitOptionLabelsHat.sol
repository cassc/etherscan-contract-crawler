// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "../trait_options/TraitOptionsHat.sol";

library TraitOptionLabelsHat {
  string constant ASTRONAUT_HELMET = "Blue Astronaut Helmet";
  string constant BAG_OF_ETHEREUM = "Bag of Ethereum";
  string constant BLACK_BOWLER_HAT = "Black Bowler Hat";
  string constant BLACK_TOP_HAT = "Black Top Hat";
  string constant BLACK_AND_WHITE_STRIPED_JAIL_CAP =
    "Black and White Striped Jail Cap";
  string constant BLACK_WITH_BLUE_HEADPHONES = "Black with Blue Headphones";
  string constant BLACK_WITH_BLUE_TOP_HAT = "Black with Blue Top Hat";
  string constant BLUE_BASEBALL_CAP = "Blue Baseball Cap";
  string constant BLUE_UMBRELLA_HAT = "Blue Umbrella Hat";
  string constant BULB_HELMET = "Bulb Helmet";
  string constant CHERRY_ON_TOP = "Cherry on Top";
  string constant CRYPTO_INFLUENCER_BLUEBIRD = "Crypto Influencer Bluebird";
  string constant GIANT_SUNFLOWER = "Giant Sunflower";
  string constant GOLD_CHALICE = "Gold Chalice";
  string constant GRADUATION_CAP_WITH_BLUE_TASSEL =
    "Graduation Cap with Blue Tassel";
  string constant GRADUATION_CAP_WITH_RED_TASSEL =
    "Graduation Cap with Red Tassel";
  string constant GREEN_GOO = "Green Goo";
  string constant NODE_OPERATORS_YELLOW_HARDHAT =
    "Node Operator's Yellow Hardhat";
  string constant NONE = "None";
  string constant PINK_BUTTERFLY = "Pink Butterfly";
  string constant PINK_SUNHAT = "Pink Sunhat";
  string constant POLICE_CAP = "Police Cap";
  string constant RED_ASTRONAUT_HELMET = "Red Astronaut Helmet";
  string constant RED_BASEBALL_CAP = "Red Baseball Cap";
  string constant RED_DEFI_WIZARD_HAT = "Red Defi Wizard Hat";
  string constant RED_SHOWER_CAP = "Red Shower Cap";
  string constant RED_SPORTS_HELMET = "Red Sports Helmet";
  string constant RED_UMBRELLA_HAT = "Red Umbrella Hat";
  string constant TAN_COWBOY_HAT = "Tan Cowboy Hat";
  string constant TAN_SUNHAT = "Tan Sunhat";
  string constant TINY_BLUE_HAT = "Tiny Blue Hat";
  string constant TINY_RED_HAT = "Tiny Red Hat";
  string constant WHITE_BOWLER_HAT = "White Bowler Hat";
  string constant WHITE_TOP_HAT = "White Top Hat";
  string constant WHITE_AND_RED_BASEBALL_CAP = "White and Red Baseball Cap";
  string constant WHITE_WITH_RED_HEADPHONES = "White with Red Headphones";
  string constant WHITE_WITH_RED_TOP_HAT = "White with Red Top Hat";
  string constant SHIRT_BLACK_AND_BLUE_BASEBALL_CAP =
    "Black and Blue Baseball Cap";
  string constant SHIRT_RED_UMBRELLA_HAT = "Red Shirt with Umbrella Hat";

  function getLabel(uint8 optionNum) public pure returns (string memory) {
    if (optionNum == TraitOptionsHat.ASTRONAUT_HELMET) {
      return ASTRONAUT_HELMET;
    } else if (optionNum == TraitOptionsHat.BAG_OF_ETHEREUM) {
      return BAG_OF_ETHEREUM;
    } else if (optionNum == TraitOptionsHat.BLACK_BOWLER_HAT) {
      return BLACK_BOWLER_HAT;
    } else if (optionNum == TraitOptionsHat.BLACK_TOP_HAT) {
      return BLACK_TOP_HAT;
    } else if (optionNum == TraitOptionsHat.BLACK_AND_WHITE_STRIPED_JAIL_CAP) {
      return BLACK_AND_WHITE_STRIPED_JAIL_CAP;
    } else if (optionNum == TraitOptionsHat.BLACK_WITH_BLUE_HEADPHONES) {
      return BLACK_WITH_BLUE_HEADPHONES;
    } else if (optionNum == TraitOptionsHat.BLACK_WITH_BLUE_TOP_HAT) {
      return BLACK_WITH_BLUE_TOP_HAT;
    } else if (optionNum == TraitOptionsHat.BLUE_BASEBALL_CAP) {
      return BLUE_BASEBALL_CAP;
    } else if (optionNum == TraitOptionsHat.BLUE_UMBRELLA_HAT) {
      return BLUE_UMBRELLA_HAT;
    } else if (optionNum == TraitOptionsHat.BULB_HELMET) {
      return BULB_HELMET;
    } else if (optionNum == TraitOptionsHat.CHERRY_ON_TOP) {
      return CHERRY_ON_TOP;
    } else if (optionNum == TraitOptionsHat.CRYPTO_INFLUENCER_BLUEBIRD) {
      return CRYPTO_INFLUENCER_BLUEBIRD;
    } else if (optionNum == TraitOptionsHat.GIANT_SUNFLOWER) {
      return GIANT_SUNFLOWER;
    } else if (optionNum == TraitOptionsHat.GOLD_CHALICE) {
      return GOLD_CHALICE;
    } else if (optionNum == TraitOptionsHat.GRADUATION_CAP_WITH_BLUE_TASSEL) {
      return GRADUATION_CAP_WITH_BLUE_TASSEL;
    } else if (optionNum == TraitOptionsHat.GRADUATION_CAP_WITH_RED_TASSEL) {
      return GRADUATION_CAP_WITH_RED_TASSEL;
    } else if (optionNum == TraitOptionsHat.GREEN_GOO) {
      return GREEN_GOO;
    } else if (optionNum == TraitOptionsHat.NODE_OPERATORS_YELLOW_HARDHAT) {
      return NODE_OPERATORS_YELLOW_HARDHAT;
    } else if (optionNum == TraitOptionsHat.NONE) {
      return NONE;
    } else if (optionNum == TraitOptionsHat.PINK_BUTTERFLY) {
      return PINK_BUTTERFLY;
    } else if (optionNum == TraitOptionsHat.PINK_SUNHAT) {
      return PINK_SUNHAT;
    } else if (optionNum == TraitOptionsHat.POLICE_CAP) {
      return POLICE_CAP;
    } else if (optionNum == TraitOptionsHat.RED_ASTRONAUT_HELMET) {
      return RED_ASTRONAUT_HELMET;
    } else if (optionNum == TraitOptionsHat.RED_BASEBALL_CAP) {
      return RED_BASEBALL_CAP;
    } else if (optionNum == TraitOptionsHat.RED_DEFI_WIZARD_HAT) {
      return RED_DEFI_WIZARD_HAT;
    } else if (optionNum == TraitOptionsHat.RED_SHOWER_CAP) {
      return RED_SHOWER_CAP;
    } else if (optionNum == TraitOptionsHat.RED_SPORTS_HELMET) {
      return RED_SPORTS_HELMET;
    } else if (optionNum == TraitOptionsHat.RED_UMBRELLA_HAT) {
      return RED_UMBRELLA_HAT;
    } else if (optionNum == TraitOptionsHat.TAN_COWBOY_HAT) {
      return TAN_COWBOY_HAT;
    } else if (optionNum == TraitOptionsHat.TAN_SUNHAT) {
      return TAN_SUNHAT;
    } else if (optionNum == TraitOptionsHat.TINY_BLUE_HAT) {
      return TINY_BLUE_HAT;
    } else if (optionNum == TraitOptionsHat.TINY_RED_HAT) {
      return TINY_RED_HAT;
    } else if (optionNum == TraitOptionsHat.WHITE_BOWLER_HAT) {
      return WHITE_BOWLER_HAT;
    } else if (optionNum == TraitOptionsHat.WHITE_TOP_HAT) {
      return WHITE_TOP_HAT;
    } else if (optionNum == TraitOptionsHat.WHITE_AND_RED_BASEBALL_CAP) {
      return WHITE_AND_RED_BASEBALL_CAP;
    } else if (optionNum == TraitOptionsHat.WHITE_WITH_RED_HEADPHONES) {
      return WHITE_WITH_RED_HEADPHONES;
    } else if (optionNum == TraitOptionsHat.WHITE_WITH_RED_TOP_HAT) {
      return WHITE_WITH_RED_TOP_HAT;
    } else if (optionNum == TraitOptionsHat.SHIRT_BLACK_AND_BLUE_BASEBALL_CAP) {
      return SHIRT_BLACK_AND_BLUE_BASEBALL_CAP;
    } else if (optionNum == TraitOptionsHat.SHIRT_RED_UMBRELLA_HAT) {
      return SHIRT_RED_UMBRELLA_HAT;
    }
    return NONE;
  }
}