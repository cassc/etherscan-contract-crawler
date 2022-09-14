// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "../trait_options/TraitOptionsFootwear.sol";

library TraitOptionLabelsFootwear {
  string constant BLACK_GLADIATOR_SANDALS = "Black Gladiator Sandals";
  string constant BLACK_SNEAKERS = "Black Sneakers";
  string constant BLACK_AND_BLUE_SNEAKERS = "Black and Blue Sneakers";
  string constant BLACK_AND_WHITE_SNEAKERS = "Black and White Sneakers";
  string constant BLUE_BASKETBALL_SNEAKERS_WITH_BLACK_STRIPE =
    "Blue Basketball Sneakers with Black Stripe";
  string constant BLUE_CROCS = "Blue Crocs";
  string constant BLUE_FLIP_FLOPS = "Blue Flip Flops";
  string constant BLUE_HIGH_HEELS = "Blue High Heels";
  string constant BLUE_SNEAKERS = "Blue Sneakers";
  string constant BLUE_TOENAIL_POLISH = "Blue Toenail Polish";
  string constant BLUE_WORK_BOOTS = "Blue Work Boots";
  string constant BLUE_AND_GRAY_BASKETBALL_SNEAKERS =
    "Blue and Gray Basketball Sneakers";
  string constant PINK_HIGH_HEELS = "Pink High Heels";
  string constant PINK_TOENAIL_POLISH = "Pink Toenail Polish";
  string constant PINK_WORK_BOOTS = "Pink Work Boots";
  string constant RED_BASKETBALL_SNEAKERS_WITH_WHITE_STRIPE =
    "Red Basketball Sneakers with White Stripe";
  string constant RED_CROCS = "Red Crocs";
  string constant RED_FLIP_FLOPS = "Red Flip Flops";
  string constant RED_HIGH_HEELS = "Red High Heels";
  string constant RED_TOENAIL_POLISH = "Red Toenail Polish";
  string constant RED_WORK_BOOTS = "Red Work Boots";
  string constant RED_AND_GRAY_BASKETBALL_SNEAKERS =
    "Red and Gray Basketball Sneakers";
  string constant STEPPED_IN_A_PUMPKIN = "Stepped in a Pumpkin";
  string constant TAN_COWBOY_BOOTS = "Tan Cowboy Boots";
  string constant TAN_WORK_BOOTS = "Tan Work Boots";
  string constant WATERMELON_SHOES = "Watermelon Shoes";
  string constant WHITE_SNEAKERS = "White Sneakers";
  string constant WHITE_AND_RED_SNEAKERS = "White and Red Sneakers";
  string constant YELLOW_RAIN_BOOTS = "Yellow Rain Boots";
  string constant NONE = "Bearfoot";

  function getLabel(uint8 optionNum) public pure returns (string memory) {
    if (optionNum == TraitOptionsFootwear.BLACK_GLADIATOR_SANDALS) {
      return BLACK_GLADIATOR_SANDALS;
    } else if (optionNum == TraitOptionsFootwear.BLACK_SNEAKERS) {
      return BLACK_SNEAKERS;
    } else if (optionNum == TraitOptionsFootwear.BLACK_AND_BLUE_SNEAKERS) {
      return BLACK_AND_BLUE_SNEAKERS;
    } else if (optionNum == TraitOptionsFootwear.BLACK_AND_WHITE_SNEAKERS) {
      return BLACK_AND_WHITE_SNEAKERS;
    } else if (
      optionNum ==
      TraitOptionsFootwear.BLUE_BASKETBALL_SNEAKERS_WITH_BLACK_STRIPE
    ) {
      return BLUE_BASKETBALL_SNEAKERS_WITH_BLACK_STRIPE;
    } else if (optionNum == TraitOptionsFootwear.BLUE_CROCS) {
      return BLUE_CROCS;
    } else if (optionNum == TraitOptionsFootwear.BLUE_FLIP_FLOPS) {
      return BLUE_FLIP_FLOPS;
    } else if (optionNum == TraitOptionsFootwear.BLUE_HIGH_HEELS) {
      return BLUE_HIGH_HEELS;
    } else if (optionNum == TraitOptionsFootwear.BLUE_SNEAKERS) {
      return BLUE_SNEAKERS;
    } else if (optionNum == TraitOptionsFootwear.BLUE_TOENAIL_POLISH) {
      return BLUE_TOENAIL_POLISH;
    } else if (optionNum == TraitOptionsFootwear.BLUE_WORK_BOOTS) {
      return BLUE_WORK_BOOTS;
    } else if (
      optionNum == TraitOptionsFootwear.BLUE_AND_GRAY_BASKETBALL_SNEAKERS
    ) {
      return BLUE_AND_GRAY_BASKETBALL_SNEAKERS;
    } else if (optionNum == TraitOptionsFootwear.PINK_HIGH_HEELS) {
      return PINK_HIGH_HEELS;
    } else if (optionNum == TraitOptionsFootwear.PINK_TOENAIL_POLISH) {
      return PINK_TOENAIL_POLISH;
    } else if (optionNum == TraitOptionsFootwear.PINK_WORK_BOOTS) {
      return PINK_WORK_BOOTS;
    } else if (
      optionNum ==
      TraitOptionsFootwear.RED_BASKETBALL_SNEAKERS_WITH_WHITE_STRIPE
    ) {
      return RED_BASKETBALL_SNEAKERS_WITH_WHITE_STRIPE;
    } else if (optionNum == TraitOptionsFootwear.RED_CROCS) {
      return RED_CROCS;
    } else if (optionNum == TraitOptionsFootwear.RED_FLIP_FLOPS) {
      return RED_FLIP_FLOPS;
    } else if (optionNum == TraitOptionsFootwear.RED_HIGH_HEELS) {
      return RED_HIGH_HEELS;
    } else if (optionNum == TraitOptionsFootwear.RED_TOENAIL_POLISH) {
      return RED_TOENAIL_POLISH;
    } else if (optionNum == TraitOptionsFootwear.RED_WORK_BOOTS) {
      return RED_WORK_BOOTS;
    } else if (
      optionNum == TraitOptionsFootwear.RED_AND_GRAY_BASKETBALL_SNEAKERS
    ) {
      return RED_AND_GRAY_BASKETBALL_SNEAKERS;
    } else if (optionNum == TraitOptionsFootwear.STEPPED_IN_A_PUMPKIN) {
      return STEPPED_IN_A_PUMPKIN;
    } else if (optionNum == TraitOptionsFootwear.TAN_COWBOY_BOOTS) {
      return TAN_COWBOY_BOOTS;
    } else if (optionNum == TraitOptionsFootwear.TAN_WORK_BOOTS) {
      return TAN_WORK_BOOTS;
    } else if (optionNum == TraitOptionsFootwear.WATERMELON_SHOES) {
      return WATERMELON_SHOES;
    } else if (optionNum == TraitOptionsFootwear.WHITE_SNEAKERS) {
      return WHITE_SNEAKERS;
    } else if (optionNum == TraitOptionsFootwear.WHITE_AND_RED_SNEAKERS) {
      return WHITE_AND_RED_SNEAKERS;
    } else if (optionNum == TraitOptionsFootwear.YELLOW_RAIN_BOOTS) {
      return YELLOW_RAIN_BOOTS;
    } else if (optionNum == TraitOptionsFootwear.NONE) {
      return NONE;
    }
    return NONE;
  }
}