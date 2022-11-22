// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

interface IMetacity {
  function getTokenTraits(uint256 tokenId) external view returns (uint256[] memory);
  function isZen(uint256 tokenId) external view returns (bool);
}