// SPDX-License-Identifier: MIT

/*
 * Created by Satoshi Nakajima (@snakajima)
 */

pragma solidity ^0.8.6;

import "../interfaces/IColorSchemes.sol";

/**
 * It makes it easy to reuse the color palette in MultiplexProvider.
 */
contract ColorSchemes is IColorSchemes {
  using Randomizer for Randomizer.Seed;

  uint constant schemeCount = 15; // Same as MultiplexProvider
  uint constant colorCount = 5;

  function getColorScheme(uint256 _assetId) external pure override returns(Randomizer.Seed memory seed, string[] memory scheme) {
    seed = Randomizer.Seed(_assetId, 0);
    uint schemeIndex;
    (seed, schemeIndex) = seed.random(schemeCount);

    string[colorCount][schemeCount] memory schemes = [
      ["FFE33A", "7FAE2E", "B1661A", "DB3F14", "F9BE02"], // genki
      ["DBF8FF", "C8FFC3", "FFB86D", "FFC6B6", "FFF4BD"], // pastel
      ["005BBB", "0072EA", "258FFF", "FFD500", "FFE040"], // ukraine
      ["5F7DE8", "D179b9", "E6B422", "38b48B", "FEF4F4"], // nippon
      ["B51802", "05933A", "0B7B48", "634D2D", "A6AAAE"], // Xmas
      ["E9B4DB", "6160B0", "EB77A6", "3E3486", "E23D80"], // love
      ["2C4269", "EABC67", "4B545E", "F98650", "0D120F"], // edo
      ["EDC9AF", "A0E2BD", "53CBCF", "0DA3BA", "046E94"], // beach
      ["FFE889", "88E7C5", "53BD99", "01767D", "034F4D"], // jungle
      ["744981", "CB6573", "FFAC00", "ED3F37", "0577A1"], // backson
      ["E28199", "D6637E", "ADDF82", "5A421B", "392713"], // sakura
      ["159F67", "66CA96", "EBFFF4", "F9BDB3", "F39385"], // spring
      ["F9CC6C", "FD9A9C", "FEE4C6", "9DD067", "3D7F97"], // summer
      ["627AA3", "D8D0C5", "DAAE46", "7AAB9C", "9F4F4C"], // vintage
      ["5A261B", "C81125", "F15B4A", "FFAB63", "FADB6A"] // fall
    ];
    scheme = new string[](colorCount);
    uint offset;
    (seed, offset) = seed.random(colorCount);
    for (uint i = 0; i < colorCount ; i++) {
      scheme[i] = schemes[schemeIndex][(i + offset) % colorCount];
    }
  }

  function generateTraits(uint256 _assetId) external pure override returns (string memory) {
    Randomizer.Seed memory seed = Randomizer.Seed(_assetId, 0);
    uint schemeIndex;
    (seed, schemeIndex) = seed.random(schemeCount);
    string[schemeCount] memory colorNames = [
      "Genki", "Pastel", "Ukraine", "Nippon", "Xmas",
      "Love", "Edo", "Beach", "Jungle", "Backson", "Sakura", "Spring", "Summer", "Vintage", "Fall"
    ];
    return string(abi.encodePacked(
      '{'
        '"trait_type":"Color Scheme",'
        '"value":"', colorNames[schemeIndex], '"' 
      '}'
    ));
  }
}