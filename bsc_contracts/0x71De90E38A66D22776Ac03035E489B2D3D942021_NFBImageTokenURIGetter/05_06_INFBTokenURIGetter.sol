// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface INFBTokenURIGetter {
  function tokenURI(
    uint256 tokenId,
    uint16 seriesId,
    uint8 editionId
  ) external view returns (string memory);
}