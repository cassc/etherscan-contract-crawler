// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "../../lib_constants/TraitDefs.sol";
import "../../lib_constants/trait_options/TraitOptionsAccessories.sol";
import "../../lib_constants/trait_options/TraitOptionsSpecies.sol";
import "./OptionSpecies.sol";
import "../Gene.sol";

library OptionAccessories {
  function getOption(uint256 dna) public pure returns (uint8) {
    uint16 accessory = Gene.getGene(TraitDefs.ACCESSORIES, dna);
    // uint16 variant = accessory % 40;
    uint16 rarityRoll = accessory % 4050;
    uint8 species = OptionSpecies.getOption(dna);

    // 1(1000) + 22(100) + 12(50) + 5(50)
    // 1000 + 2200 + 600 + 250
    // 4050

    if (rarityRoll < 1000) {
      return TraitOptionsAccessories.NONE;
    } else if (rarityRoll >= 1000 && rarityRoll < 3200) {
      // return 100 weight
      uint16 coinFlip = rarityRoll % 2;
      uint16 variant = rarityRoll % 17;

      // if BLACK or panda
      if (species != TraitOptionsSpecies.POLAR && coinFlip == 0) {
        if (variant == 0) {
          return TraitOptionsAccessories.BLUE_BALLOON;
        } else if (variant == 1) {
          return TraitOptionsAccessories.BLUE_BOXING_GLOVES;
        } else if (variant == 2) {
          return TraitOptionsAccessories.BLUE_FINGERNAIL_POLISH;
        } else if (variant == 3) {
          return TraitOptionsAccessories.BLUE_GARDENER_TROWEL;
        } else if (variant == 4) {
          return TraitOptionsAccessories.BLUE_MERGE_BEARS_FOAM_FINGER;
        } else if (variant == 5) {
          return TraitOptionsAccessories.BLUE_PURSE;
        } else if (variant == 6) {
          return TraitOptionsAccessories.BLUE_SPATULA;
        } else if (variant == 7) {
          return TraitOptionsAccessories.BUCKET_OF_BLUE_PAINT;
        } else if (variant == 8) {
          return TraitOptionsAccessories.HAND_IN_A_BLUE_COOKIE_JAR;
        } else if (variant == 9) {
          return
            TraitOptionsAccessories.PICNIC_BASKET_WITH_BLUE_AND_WHITE_BLANKET;
        }
      }

      if (species != TraitOptionsSpecies.BLACK && coinFlip == 1) {
        // if polar or panda
        if (variant == 0) {
          return TraitOptionsAccessories.BUCKET_OF_RED_PAINT;
        } else if (variant == 1) {
          return TraitOptionsAccessories.HAND_IN_A_RED_COOKIE_JAR;
        } else if (variant == 2) {
          return
            TraitOptionsAccessories.PICNIC_BASKET_WITH_RED_AND_WHITE_BLANKET;
        } else if (variant == 3) {
          return TraitOptionsAccessories.RED_BALLOON;
        } else if (variant == 4) {
          return TraitOptionsAccessories.RED_BOXING_GLOVES;
        } else if (variant == 5) {
          return TraitOptionsAccessories.RED_FINGERNAIL_POLISH;
        } else if (variant == 6) {
          return TraitOptionsAccessories.RED_GARDENER_TROWEL;
        } else if (variant == 7) {
          return TraitOptionsAccessories.RED_MERGE_BEARS_FOAM_FINGER;
        } else if (variant == 8) {
          return TraitOptionsAccessories.RED_PURSE;
        } else if (variant == 9) {
          return TraitOptionsAccessories.RED_SPATULA;
        }
      }

      if (variant == 10) {
        return TraitOptionsAccessories.PINK_FINGERNAIL_POLISH;
      } else if (variant == 11) {
        return TraitOptionsAccessories.PINK_PURSE;
      } else if (variant == 12) {
        return TraitOptionsAccessories.BANHAMMER;
      } else if (variant == 13) {
        return TraitOptionsAccessories.BEEHIVE_ON_A_STICK;
      } else if (variant == 14) {
        return TraitOptionsAccessories.DOUBLE_DUMBBELLS;
      } else if (variant == 15) {
        return TraitOptionsAccessories.TOILET_PAPER;
      } else if (variant == 16) {
        return TraitOptionsAccessories.WOODEN_WALKING_CANE;
      }
    } else if (rarityRoll >= 3200 && rarityRoll < 3800) {
      uint16 variant = rarityRoll % 17;

      // return 50 weight
      if (variant == 1) {
        return TraitOptionsAccessories.BAMBOO_SWORD;
      }
      if (
        variant == 2 &&
        species != TraitOptionsSpecies.BLACK &&
        species != TraitOptionsSpecies.POLAR
      ) {
        return TraitOptionsAccessories.BASKET_OF_EXCESS_USED_GRAPHICS_CARDS;
      } else if (
        variant == 3 &&
        species != TraitOptionsSpecies.BLACK &&
        species != TraitOptionsSpecies.POLAR
      ) {
        return TraitOptionsAccessories.BURNED_OUT_GRAPHICS_CARD;
      } else if (
        variant == 4 &&
        species != TraitOptionsSpecies.PANDA &&
        species != TraitOptionsSpecies.REVERSE_PANDA &&
        species != TraitOptionsSpecies.GOLD_PANDA
      ) {
        return TraitOptionsAccessories.MINERS_PICKAXE;
      } else if (variant == 5) {
        return TraitOptionsAccessories.NINJA_SWORDS;
      } else if (
        variant == 6 &&
        species != TraitOptionsSpecies.BLACK &&
        species != TraitOptionsSpecies.POLAR
      ) {
        return TraitOptionsAccessories.PROOF_OF_RIBEYE_STEAK;
      } else if (variant == 7) {
        return TraitOptionsAccessories.FRESH_SALMON;
      }
    } else if (rarityRoll >= 3800) {
      uint16 variant = rarityRoll % 4;

      // return 25 weight
      if (variant == 0) {
        return TraitOptionsAccessories.PHISHING_NET;
      } else if (variant == 1) {
        return TraitOptionsAccessories.PHISHING_ROD;
      }
      if (variant == 2) {
        return TraitOptionsAccessories.COLD_STORAGE_WALLET;
      } else if (variant == 3) {
        return TraitOptionsAccessories.HOT_WALLET;
      }
    }
    return TraitOptionsAccessories.NONE;
  }
}