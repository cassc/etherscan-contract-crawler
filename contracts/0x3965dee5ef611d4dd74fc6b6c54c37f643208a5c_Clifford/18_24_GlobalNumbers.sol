// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "./GridHelper.sol";

import "./Noise.sol";

library GlobalNumbers {

  uint internal constant FLIPPER_WRAPPER_NUMBER = 13010;
  uint internal constant CHAR_MASK_GROUP_NUMBER = 14006;

  uint internal constant GROUP_CLOSE_NUMBER = 13000;

  // Small Asset numbers
  // 00000 - None
  // 06022 - Rat
  // 06021 - Skull
  // 06028 - Dead Plant
  // 06014 - Dog Bowl
  // 06027 - Bottle
  // 06026 - Can
  // 06006 - Bong
  // 06004 - Martini
  // 06011 - Books
  // 06000 - Lavalamp
  // 06025 - Pineapple
  // 06029 - Watermelon
  // 06020 - Lizard

  string internal constant SMALL_ASSET_NUMBERS = "0000006022060210602806014060270602606006060040601106000060250602906020";

  // Large Asset numbers
  // 00000 - None
  // 02002 - Pit
  // 06013 - Toilet
  // 02001 - Pit with Grate
  // 02009 - Spikes B
  // 02008 - Spikes A
  // 02004 - Ladder
  // 02003 - Stairs
  // 06008 - Fridge
  // 06019 - Stool
  // 06009 - Circular Rug
  // 06023 - Desk Chair
  // 06024 - Cactus (Large)
  // 06030 - Gramaphone
  // 06018 - Cello
  // 06017 - Harp

  string internal constant LARGE_ASSET_NUMBERS = "00000020020601302001020090200802004020030600806019060090602306024060300601806017";

  // Out Wall numbers
  // 06005 - Peephole A
  // 06007 - Peephole B
  // 06016 - Megaphone
  // 06010 - CCTV

  string internal constant OUT_WALL_NUMBERS = "0000006005060070601606010";

  // Flat Wall numbers
  // 02000 - Crack
  // 02011 - Numbers
  // 02007 - Recess C
  // 02006 - Recess B
  // 02005 - Recess A
  // 02010 - Wall Rug
  
  string internal constant FLAT_WALL_NUMBERS = "00000020000201102007020060200502010";

  // Expansion Props - 9 values
  // None
  // Crack
  // Recess A
  // Recess B
  // Recess C
  // Pit
  // Grate
  // Stairs
  // Ladder

  string internal constant EXPANSION_PROPS_NUMBERS = "000000200002005020060200702002020010200302004";

  // Character Lever - 8 values
  // LEVER D
  // LEVER C
  // LEVER B
  // LEVER A
  // DETAILED LEVER D
  // DETAILED LEVER C
  // DETAILED LEVER B
  // DETAILED LEVER A

  string internal constant CHARACTER_LEVER_NUMBERS = "0300003001030020300303016030170301803019";

  // Character - 7 values
  // 00000 - None
  // 14002 - COLLAPSED
  // 14005 - HUNCHED
  // 14003 - SLOUCHED
  // 14001 - STANDING
  // 14000 - SITTING
  // 14004 - MEDITATING

  string internal constant CHARACTER_NUMBERS = "00000140021400514003140011400014004";

  /**
    * @dev Returns the small asset number based on the digits
    * @param rand The digits to use
    * @return The small asset number
   */

  function getSmallAssetNumber(uint rand, int baseline) external pure returns (uint) {
    uint smallAssetDigits = GridHelper.constrainToHex(Noise.getNoiseArrayOne()[GridHelper.getRandByte(rand, 20)] + baseline);

    return GridHelper.getSingleObject(SMALL_ASSET_NUMBERS, smallAssetDigits, 14, 5);
  }

  /**
    * @dev Returns the large asset number based on the digits
    * @param rand The digits to use
    * @return The large asset number
   */

  function getLargeAssetNumber(uint rand, int baseline) external pure returns (uint) {
    uint largeAssetDigits = GridHelper.constrainToHex(Noise.getNoiseArrayOne()[GridHelper.getRandByte(rand, 21)] + baseline);

    return GridHelper.getSingleObject(LARGE_ASSET_NUMBERS, largeAssetDigits, 16, 5);
  }

  /**
    * @dev Returns the out wall number based on the digits
    * @param rand The digits to use
    * @return The out wall number
   */

  function getOutWallNumber(uint rand, int baseline) external pure returns (uint) {
    uint outWallDigits = GridHelper.constrainToHex(Noise.getNoiseArrayOne()[GridHelper.getRandByte(rand, 22)] + baseline);

    return GridHelper.getSingleObject(OUT_WALL_NUMBERS, outWallDigits, 5, 5);
  }

  /**
    * @dev Returns the flat wall number based on the digits
    * @param rand The digits to use
    * @return The flat wall number
   */

  function getFlatWallNumber(uint rand, int baseline) external pure returns (uint) {
    uint flatWallDigits = GridHelper.constrainToHex(Noise.getNoiseArrayOne()[GridHelper.getRandByte(rand, 23)] + baseline);

    return GridHelper.getSingleObject(FLAT_WALL_NUMBERS, flatWallDigits, 7, 5);
  }

  /**
    * @dev Returns the character lever number based on the digits and state
    * @param rand The digits to use
    * @return The character lever number
   */

  function getCharacterLeverNumber(uint rand, int baseline) internal pure returns (uint) {
    uint characterLeverDigits = GridHelper.constrainToHex(Noise.getNoiseArrayOne()[GridHelper.getRandByte(rand, 30)] + baseline);

    return GridHelper.getSingleObject(CHARACTER_LEVER_NUMBERS, characterLeverDigits, 8, 5);
  }

  /**
    * @dev Returns the character number based on the digits and state
    * @param rand The digits to use
    * @return The character number
   */

  function getCharacterNumber(uint rand, int baseline) internal pure returns (uint) {
    uint characterDigits = GridHelper.constrainToHex(Noise.getNoiseArrayTwo()[GridHelper.getRandByte(rand, 31)] + baseline);

    return GridHelper.getSingleObject(CHARACTER_NUMBERS, characterDigits, 7, 5);
  }

  /**
    * @dev Returns the character number and lever number based on the digits and state
    * @param rand The digits to use
    * @param flip Whether to flip the character
    * @return The character number and lever numbers
   */
  function getCharacterNumberAndLeverNumber(uint rand, bool flip, int baseline) external pure returns (uint[5] memory) {
    uint characterNumber = getCharacterNumber(rand, baseline);
    uint characterLeverNumber = getCharacterLeverNumber(rand, baseline);
    uint armMask = 0;
    if (characterNumber == 14001 || characterNumber == 14003 || characterNumber == 14005) {
      armMask = CHAR_MASK_GROUP_NUMBER;
    }

    uint flipOpen = 0;
    uint flipClose = 0;
    if (flip) {
      flipOpen = FLIPPER_WRAPPER_NUMBER;
      flipClose = GROUP_CLOSE_NUMBER;
    }

    return [flipOpen, characterLeverNumber, armMask, characterNumber, flipClose];
  }

  /**
    * @dev Returns the expansion prop number based on the digits
    * @param rand The digits to use
    * @param baseline The baseline to use
    * @param offsetNumbers The offset numbers to use
    * @param numOptions The number of options
    * @return The expansion prop number
   */

  function getSingleOffset(uint rand, int baseline, string memory offsetNumbers, uint numOptions) external pure returns (string memory) {
    uint offsetDigits1 = GridHelper.constrainToHex(Noise.getNoiseArrayOne()[GridHelper.getRandByte(rand, 20)] + baseline);
    uint offsetDigits2 = GridHelper.constrainToHex(Noise.getNoiseArrayOne()[GridHelper.getRandByte(rand, 21)] + baseline);
    uint offsetDigits3 = GridHelper.constrainToHex(Noise.getNoiseArrayOne()[GridHelper.getRandByte(rand, 22)] + baseline);

    uint finalOffsetDigits = (offsetDigits1 + offsetDigits2 + offsetDigits3) / 3;

    return string(GridHelper.slice(bytes(offsetNumbers), (finalOffsetDigits % numOptions)*8, 8));
  }
}