// SPDX-License-Identifier: MIT
// coded by @eddietree

pragma solidity ^0.8.0;

interface IEthKunRenderer{
  function getSVG(uint256 seed, uint256 level) external view returns (string memory);
  function getUnrevealedSVG(uint256 seed) external view returns (string memory);
  function getTraitsMetadata(uint256 seed) external view returns (string memory);
}