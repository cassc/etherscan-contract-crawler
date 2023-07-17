// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.0 <0.9.0;

contract MFiendCharacteristics {
  //Basic types
  uint8 private constant PROTOTYPICAL = 0;
  uint8 private constant VIBRANT = 1;

  //Elemental types
  uint8 private constant PLASMIC = 2;
  uint8 private constant FLUID = 3;
  uint8 private constant ORGANIC = 4;

  //Elemental types
  uint8 private constant UMBRAL = 5;
  uint8 private constant LUMINOUS = 6;
  uint8 private constant ABYSSAL = 7;

  uint256 private constant MASK = 0xFF0000FF0000FF0000FF0000FF0000FF0000FF0000FF0000FF0000FF0000;

  string[] public affinityToName = [
    "Prototypical",
    "Vibrant",
    "Plasmic",
    "Fluid",
    "Organic",
    "Umbral",
    "Luminous",
    "Abyssal"
  ];

  uint24[8] public affinityToColor = [
    0xc7c5c5,
    0xfbc9ff,
    0xffc9c9,
    0xc9e0ff,
    0xdffade,
    0x796791,
    0xfffef0,
    0x171717
  ];

  function getAffinity(uint256 tokenData) public pure returns (uint256) {
    // roll is out of 32
    uint256 roll = (tokenData >> 251);

    if (roll == 0) {
      return ABYSSAL;
    }
    if (roll <= 2) {
      return UMBRAL;
    }
    if (roll <= 4) {
      return LUMINOUS;
    }
    if (roll <= 8) {
      return PLASMIC;
    }
    if (roll <= 12) {
      return FLUID;
    }
    if (roll <= 16) {
      return ORGANIC;
    }
    if (roll <= 24) {
      return VIBRANT;
    }
    return PROTOTYPICAL;
  }

  function getUmbralColor(uint256 color) internal pure returns (uint256) {
    return color % 64;
  }

  function getLuminousColor(uint256 color) internal pure returns (uint256) {
    return 192 + (color % 64);
  }

  function getPrototypicalColor(uint256 color) internal pure returns (uint256) {
    return 112 + (color % 32);
  }

  function getAdjustedColors(uint256 tokenData, function(uint256) pure returns (uint256) adjuster)
    internal
    pure
    returns (uint256)
  {
    uint256 palette;
    for (uint256 i = 0; i < 10; i += 1) {
      uint256 shifted = tokenData >> (i * 24);
      uint256 r = shifted & 0xFF;
      uint256 g = (shifted & 0xFF00) >> 8;
      uint256 b = (shifted & 0xFF0000) >> 16;

      uint256 rAdjusted = adjuster(r);
      uint256 gAdjusted = adjuster(g);
      uint256 bAdjusted = adjuster(b);

      uint256 packedColor = bAdjusted + (gAdjusted << 8) + (rAdjusted << 16);

      palette = palette + (packedColor << (i * 24));
    }
    return palette;
  }

  function protoypicalPalette(uint256 tokenData) internal pure returns (uint256) {
    return getAdjustedColors(tokenData, getPrototypicalColor);
  }

  function umbralPalette(uint256 tokenData) internal pure returns (uint256) {
    return getAdjustedColors(tokenData, getUmbralColor);
  }

  function luminousPalette(uint256 tokenData) internal pure returns (uint256) {
    return getAdjustedColors(tokenData, getLuminousColor);
  }

  function plasmicPalette(uint256 tokenData) internal pure returns (uint256) {
    uint256 masked = (tokenData & (MASK >> 8)) + (tokenData & (MASK >> 16));
    return masked + MASK;
  }

  function fluidPalette(uint256 tokenData) internal pure returns (uint256) {
    uint256 masked = (tokenData & (MASK >> 8)) + (tokenData & (MASK));
    return masked + (MASK >> 16);
  }

  function organicPalette(uint256 tokenData) internal pure returns (uint256) {
    uint256 masked = (tokenData & (MASK)) + (tokenData & (MASK >> 16));
    return masked + (MASK >> 8);
  }

  function abyssalPalette(uint256 tokenData) internal pure returns (uint256) {
    uint256 masked = tokenData & MASK;
    return masked + (masked >> 8) + (masked >> 16);
  }

  function getPalette(uint256 tokenData, uint256 affinity) public pure returns (uint256) {
    if (affinity == PROTOTYPICAL) {
      return protoypicalPalette(tokenData);
    }

    if (affinity == VIBRANT) {
      return tokenData;
    }

    if (affinity == PLASMIC) {
      return plasmicPalette(tokenData);
    }

    if (affinity == FLUID) {
      return fluidPalette(tokenData);
    }

    if (affinity == ORGANIC) {
      return organicPalette(tokenData);
    }

    if (affinity == UMBRAL) {
      return umbralPalette(tokenData);
    }

    if (affinity == LUMINOUS) {
      return luminousPalette(tokenData);
    }

    return abyssalPalette(tokenData);
  }
}