// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.20;

/**
 *  @title DNA
 *  @notice This library implements the DNA as defined by OpenAvatar.
 *  @dev The DNA string is a 32-byte hex string. The DNA string is immutable.
 *  The bytes represent the following:
 *  ZZZZ YYYY XXXX WWWW VVVV UUUU TTTT SSSS
 *  0000 0000 0000 0000 0000 0000 0000 0000
 *
 *    Bytes  |  Chars  | Description
 *  ---------|---------|-------------
 *   [0:1]   | [0:3]   |  body
 *   [2:3]   | [4:7]   |  tattoos
 *   [4:5]   | [8:11]  |  makeup
 *   [6:7]   | [12:15] |  left eye
 *   [8:9]   | [16:19] |  right eye
 *   [10:11] | [20:23] |  bottomwear
 *   [12:13] | [24:27] |  footwear
 *   [14:15] | [28:31] |  topwear
 *   [16:17] | [32:35] |  handwear
 *   [18:19] | [36:39] |  outerwear
 *   [20:21] | [40:43] |  jewelry
 *   [22:23] | [44:47] |  facial hair
 *   [24:25] | [48:51] |  facewear
 *   [26:27] | [52:55] |  eyewear
 *   [28:29] | [56:59] |  hair
 *   [30:31] | [60:63] |  reserved
 *
 *  Each 2-byte section is a struct of the following:
 *    [0] | [0:1] |  pattern
 *    [1] | [2:3] |  palette
 *
 * The pattern is an index into the pattern array.
 * The palette is an index into the palette array.
 */
library DNA {
  /////////////////////////////////////////////////////////////////////////////
  /// Body
  /////////////////////////////////////////////////////////////////////////////
  /// bytes [0:1]

  /// @notice Returns the body pattern index from the DNA.
  function bodyPattern(bytes32 self) internal pure returns (uint8) {
    return uint8(self[0]);
  }

  /// @notice Returns the body palette index from the DNA.
  function bodyPalette(bytes32 self) internal pure returns (uint8) {
    return uint8(self[1]);
  }

  /////////////////////////////////////////////////////////////////////////////
  /// Tattoos
  /////////////////////////////////////////////////////////////////////////////
  /// bytes [2:3]

  /// @notice Returns the tattoos pattern index from the DNA.
  function tattoosPattern(bytes32 self) internal pure returns (uint8) {
    return uint8(self[2]);
  }

  /// @notice Returns the tattoos palette index from the DNA.
  function tattoosPalette(bytes32 self) internal pure returns (uint8) {
    return uint8(self[3]);
  }

  /////////////////////////////////////////////////////////////////////////////
  /// Makeup
  /////////////////////////////////////////////////////////////////////////////
  /// bytes [4:5]

  /// @notice Returns the makeup pattern index from the DNA.
  function makeupPattern(bytes32 self) internal pure returns (uint8) {
    return uint8(self[4]);
  }

  /// @notice Returns the makeup palette index from the DNA.
  function makeupPalette(bytes32 self) internal pure returns (uint8) {
    return uint8(self[5]);
  }

  /////////////////////////////////////////////////////////////////////////////
  /// Left Eye
  /////////////////////////////////////////////////////////////////////////////
  /// bytes [6:7]

  /// @notice Returns the left eye pattern index from the DNA.
  function leftEyePattern(bytes32 self) internal pure returns (uint8) {
    return uint8(self[6]);
  }

  /// @notice Returns the left eye palette index from the DNA.
  function leftEyePalette(bytes32 self) internal pure returns (uint8) {
    return uint8(self[7]);
  }

  /////////////////////////////////////////////////////////////////////////////
  /// Right Eye
  /////////////////////////////////////////////////////////////////////////////
  /// bytes [8:9]

  /// @notice Returns the right eye pattern index from the DNA.
  function rightEyePattern(bytes32 self) internal pure returns (uint8) {
    return uint8(self[8]);
  }

  /// @notice Returns the right eye palette index from the DNA.
  function rightEyePalette(bytes32 self) internal pure returns (uint8) {
    return uint8(self[9]);
  }

  /////////////////////////////////////////////////////////////////////////////
  /// Bottomwear
  /////////////////////////////////////////////////////////////////////////////
  /// bytes [10:11]

  /// @notice Returns the bottomwear pattern index from the DNA.
  function bottomwearPattern(bytes32 self) internal pure returns (uint8) {
    return uint8(self[10]);
  }

  /// @notice Returns the bottomwear palette index from the DNA.
  function bottomwearPalette(bytes32 self) internal pure returns (uint8) {
    return uint8(self[11]);
  }

  /////////////////////////////////////////////////////////////////////////////
  /// Footwear
  /////////////////////////////////////////////////////////////////////////////
  /// bytes [12:13]

  /// @notice Returns the footwear pattern index from the DNA.
  function footwearPattern(bytes32 self) internal pure returns (uint8) {
    return uint8(self[12]);
  }

  /// @notice Returns the footwear palette index from the DNA.
  function footwearPalette(bytes32 self) internal pure returns (uint8) {
    return uint8(self[13]);
  }

  /////////////////////////////////////////////////////////////////////////////
  /// Topwear
  /////////////////////////////////////////////////////////////////////////////
  /// bytes [14:15]

  /// @notice Returns the topwear pattern index from the DNA.
  function topwearPattern(bytes32 self) internal pure returns (uint8) {
    return uint8(self[14]);
  }

  /// @notice Returns the topwear palette index from the DNA.
  function topwearPalette(bytes32 self) internal pure returns (uint8) {
    return uint8(self[15]);
  }

  /////////////////////////////////////////////////////////////////////////////
  /// Handwear
  /////////////////////////////////////////////////////////////////////////////
  /// bytes [16:17]

  /// @notice Returns the handwear pattern index from the DNA.
  function handwearPattern(bytes32 self) internal pure returns (uint8) {
    return uint8(self[16]);
  }

  /// @notice Returns the handwear palette index from the DNA.
  function handwearPalette(bytes32 self) internal pure returns (uint8) {
    return uint8(self[17]);
  }

  /////////////////////////////////////////////////////////////////////////////
  /// Outerwear
  /////////////////////////////////////////////////////////////////////////////
  /// bytes [18:19]

  /// @notice Returns the outerwear pattern index from the DNA.
  function outerwearPattern(bytes32 self) internal pure returns (uint8) {
    return uint8(self[18]);
  }

  /// @notice Returns the outerwear palette index from the DNA.
  function outerwearPalette(bytes32 self) internal pure returns (uint8) {
    return uint8(self[19]);
  }

  /////////////////////////////////////////////////////////////////////////////
  /// Jewelry
  /////////////////////////////////////////////////////////////////////////////
  /// bytes [20:21]

  /// @notice Returns the jewelry pattern index from the DNA.
  function jewelryPattern(bytes32 self) internal pure returns (uint8) {
    return uint8(self[20]);
  }

  /// @notice Returns the jewelry palette index from the DNA.
  function jewelryPalette(bytes32 self) internal pure returns (uint8) {
    return uint8(self[21]);
  }

  /////////////////////////////////////////////////////////////////////////////
  /// Facial Hair
  /////////////////////////////////////////////////////////////////////////////
  /// bytes [22:23]

  /// @notice Returns the facial hair pattern index from the DNA.
  function facialHairPattern(bytes32 self) internal pure returns (uint8) {
    return uint8(self[22]);
  }

  /// @notice Returns the facial hair palette index from the DNA.
  function facialHairPalette(bytes32 self) internal pure returns (uint8) {
    return uint8(self[23]);
  }

  /////////////////////////////////////////////////////////////////////////////
  /// Facewear
  /////////////////////////////////////////////////////////////////////////////
  /// bytes [24:25]

  /// @notice Returns the facewear pattern index from the DNA.
  function facewearPattern(bytes32 self) internal pure returns (uint8) {
    return uint8(self[24]);
  }

  /// @notice Returns the facewear palette index from the DNA.
  function facewearPalette(bytes32 self) internal pure returns (uint8) {
    return uint8(self[25]);
  }

  /////////////////////////////////////////////////////////////////////////////
  /// Eyewear
  /////////////////////////////////////////////////////////////////////////////
  /// bytes [26:27]

  /// @notice Returns the eyewear pattern index from the DNA.
  function eyewearPattern(bytes32 self) internal pure returns (uint8) {
    return uint8(self[26]);
  }

  /// @notice Returns the eyewear palette index from the DNA.
  function eyewearPalette(bytes32 self) internal pure returns (uint8) {
    return uint8(self[27]);
  }

  /////////////////////////////////////////////////////////////////////////////
  /// Hair
  /////////////////////////////////////////////////////////////////////////////
  /// bytes [28:29]

  /// @notice Returns the hair pattern index from the DNA.
  function hairPattern(bytes32 self) internal pure returns (uint8) {
    return uint8(self[28]);
  }

  /// @notice Returns the hair palette index from the DNA.
  function hairPalette(bytes32 self) internal pure returns (uint8) {
    return uint8(self[29]);
  }
}