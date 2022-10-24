// SPDX-License-Identifier: MIT

/*
 * Created by Satoshi Nakajima (@snakajima)
 */

pragma solidity ^0.8.6;

import "randomizer.sol/Randomizer.sol";

interface IColorSchemes {
  function getColorScheme(uint256 _assetId) external view returns(Randomizer.Seed memory seed, string[] memory scheme);
  function generateTraits(uint256 _assetId) external view returns (string memory);
}