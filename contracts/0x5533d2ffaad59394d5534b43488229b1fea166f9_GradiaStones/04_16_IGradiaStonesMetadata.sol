// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.0;

interface IGradiaStonesMetadata {
  function getMetadata(
    uint256 tokenId
  ) external view returns (string memory);
}