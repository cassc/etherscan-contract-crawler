// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "../trait_options/TraitOptionsAccessories.sol";

library TraitOptionLabelsAccessories {
  string constant BALL_AND_CHAIN = "Ball and Chain";
  string constant BAMBOO_SWORD = "Bamboo Sword";
  string constant BANHAMMER = "Banhammer";
  string constant BASKET_OF_EXCESS_USED_GRAPHICS_CARDS =
    "Basket of Excess Used Graphics Cards";
  string constant BEEHIVE_ON_A_STICK = "Beehive on a Stick";
  string constant BLUE_BALLOON = "Blue Balloon";
  string constant BLUE_BOXING_GLOVES = "Blue Boxing Gloves";
  string constant BLUE_FINGERNAIL_POLISH = "Blue Fingernail Polish";
  string constant BLUE_GARDENER_TROWEL = "Blue Gardener Trowel";
  string constant BLUE_MERGE_BEARS_FOAM_FINGER = "Blue Merge Bears Foam Finger";
  string constant BLUE_PURSE = "Blue Purse";
  string constant BLUE_SPATULA = "Blue Spatula";
  string constant BUCKET_OF_BLUE_PAINT = "Bucket of Blue Paint";
  string constant BUCKET_OF_RED_PAINT = "Bucket of Red Paint";
  string constant BURNED_OUT_GRAPHICS_CARD = "Burned Out Graphics Card";
  string constant COLD_STORAGE_WALLET = "Cold Storage Wallet";
  string constant DOUBLE_DUMBBELLS = "Double Dumbbells";
  string constant FRESH_SALMON = "Fresh Salmon";
  string constant HAND_IN_A_BLUE_COOKIE_JAR = "Hand in a Blue Cookie Jar";
  string constant HAND_IN_A_RED_COOKIE_JAR = "Hand in a Red Cookie Jar";
  string constant HOT_WALLET = "Hot Wallet";
  string constant MINERS_PICKAXE = "Miner's Pickaxe";
  string constant NINJA_SWORDS = "Ninja Swords";
  string constant NONE = "None";
  string constant PHISHING_NET = "Phishing Net";
  string constant PHISHING_ROD = "Phishing Rod";
  string constant PICNIC_BASKET_WITH_BLUE_AND_WHITE_BLANKET =
    "Picnic Basket with Blue and White Blanket";
  string constant PICNIC_BASKET_WITH_RED_AND_WHITE_BLANKET =
    "Picnic Basket with Red and White Blanket";
  string constant PINK_FINGERNAIL_POLISH = "Pink Fingernail Polish";
  string constant PINK_PURSE = "Pink Purse";
  string constant PROOF_OF_RIBEYE_STEAK = "Proof of Ribeye Steak";
  string constant RED_BALLOON = "Red Balloon";
  string constant RED_BOXING_GLOVES = "Red Boxing Gloves";
  string constant RED_FINGERNAIL_POLISH = "Red Fingernail Polish";
  string constant RED_GARDENER_TROWEL = "Red Gardener Trowel";
  string constant RED_MERGE_BEARS_FOAM_FINGER = "Red Merge Bears Foam Finger";
  string constant RED_PURSE = "Red Purse";
  string constant RED_SPATULA = "Red Spatula";
  string constant TOILET_PAPER = "Toilet Paper";
  string constant WOODEN_WALKING_CANE = "Wooden Walking Cane";

  function getLabel(uint8 optionNum) public pure returns (string memory) {
    if (optionNum == TraitOptionsAccessories.BALL_AND_CHAIN) {
      return BALL_AND_CHAIN;
    } else if (optionNum == TraitOptionsAccessories.BAMBOO_SWORD) {
      return BAMBOO_SWORD;
    } else if (optionNum == TraitOptionsAccessories.BANHAMMER) {
      return BANHAMMER;
    } else if (
      optionNum == TraitOptionsAccessories.BASKET_OF_EXCESS_USED_GRAPHICS_CARDS
    ) {
      return BASKET_OF_EXCESS_USED_GRAPHICS_CARDS;
    } else if (optionNum == TraitOptionsAccessories.BEEHIVE_ON_A_STICK) {
      return BEEHIVE_ON_A_STICK;
    } else if (optionNum == TraitOptionsAccessories.BLUE_BALLOON) {
      return BLUE_BALLOON;
    } else if (optionNum == TraitOptionsAccessories.BLUE_BOXING_GLOVES) {
      return BLUE_BOXING_GLOVES;
    } else if (optionNum == TraitOptionsAccessories.BLUE_FINGERNAIL_POLISH) {
      return BLUE_FINGERNAIL_POLISH;
    } else if (optionNum == TraitOptionsAccessories.BLUE_GARDENER_TROWEL) {
      return BLUE_GARDENER_TROWEL;
    } else if (
      optionNum == TraitOptionsAccessories.BLUE_MERGE_BEARS_FOAM_FINGER
    ) {
      return BLUE_MERGE_BEARS_FOAM_FINGER;
    } else if (optionNum == TraitOptionsAccessories.BLUE_PURSE) {
      return BLUE_PURSE;
    } else if (optionNum == TraitOptionsAccessories.BLUE_SPATULA) {
      return BLUE_SPATULA;
    } else if (optionNum == TraitOptionsAccessories.BUCKET_OF_BLUE_PAINT) {
      return BUCKET_OF_BLUE_PAINT;
    } else if (optionNum == TraitOptionsAccessories.BUCKET_OF_RED_PAINT) {
      return BUCKET_OF_RED_PAINT;
    } else if (optionNum == TraitOptionsAccessories.BURNED_OUT_GRAPHICS_CARD) {
      return BURNED_OUT_GRAPHICS_CARD;
    } else if (optionNum == TraitOptionsAccessories.COLD_STORAGE_WALLET) {
      return COLD_STORAGE_WALLET;
    } else if (optionNum == TraitOptionsAccessories.DOUBLE_DUMBBELLS) {
      return DOUBLE_DUMBBELLS;
    } else if (optionNum == TraitOptionsAccessories.FRESH_SALMON) {
      return FRESH_SALMON;
    } else if (optionNum == TraitOptionsAccessories.HAND_IN_A_BLUE_COOKIE_JAR) {
      return HAND_IN_A_BLUE_COOKIE_JAR;
    } else if (optionNum == TraitOptionsAccessories.HAND_IN_A_RED_COOKIE_JAR) {
      return HAND_IN_A_RED_COOKIE_JAR;
    } else if (optionNum == TraitOptionsAccessories.HOT_WALLET) {
      return HOT_WALLET;
    } else if (optionNum == TraitOptionsAccessories.MINERS_PICKAXE) {
      return MINERS_PICKAXE;
    } else if (optionNum == TraitOptionsAccessories.NINJA_SWORDS) {
      return NINJA_SWORDS;
    } else if (optionNum == TraitOptionsAccessories.NONE) {
      return NONE;
    } else if (
      optionNum ==
      TraitOptionsAccessories.PICNIC_BASKET_WITH_BLUE_AND_WHITE_BLANKET
    ) {
      return PICNIC_BASKET_WITH_BLUE_AND_WHITE_BLANKET;
    } else if (
      optionNum ==
      TraitOptionsAccessories.PICNIC_BASKET_WITH_RED_AND_WHITE_BLANKET
    ) {
      return PICNIC_BASKET_WITH_RED_AND_WHITE_BLANKET;
    } else if (optionNum == TraitOptionsAccessories.PINK_FINGERNAIL_POLISH) {
      return PINK_FINGERNAIL_POLISH;
    } else if (optionNum == TraitOptionsAccessories.PROOF_OF_RIBEYE_STEAK) {
      return PROOF_OF_RIBEYE_STEAK;
    } else if (optionNum == TraitOptionsAccessories.RED_BALLOON) {
      return RED_BALLOON;
    } else if (optionNum == TraitOptionsAccessories.RED_BOXING_GLOVES) {
      return RED_BOXING_GLOVES;
    } else if (optionNum == TraitOptionsAccessories.RED_FINGERNAIL_POLISH) {
      return RED_FINGERNAIL_POLISH;
    } else if (optionNum == TraitOptionsAccessories.RED_GARDENER_TROWEL) {
      return RED_GARDENER_TROWEL;
    } else if (
      optionNum == TraitOptionsAccessories.RED_MERGE_BEARS_FOAM_FINGER
    ) {
      return RED_MERGE_BEARS_FOAM_FINGER;
    } else if (optionNum == TraitOptionsAccessories.RED_PURSE) {
      return RED_PURSE;
    } else if (optionNum == TraitOptionsAccessories.RED_SPATULA) {
      return RED_SPATULA;
    } else if (optionNum == TraitOptionsAccessories.TOILET_PAPER) {
      return TOILET_PAPER;
    } else if (optionNum == TraitOptionsAccessories.WOODEN_WALKING_CANE) {
      return WOODEN_WALKING_CANE;
    }
    return NONE;
  }
}