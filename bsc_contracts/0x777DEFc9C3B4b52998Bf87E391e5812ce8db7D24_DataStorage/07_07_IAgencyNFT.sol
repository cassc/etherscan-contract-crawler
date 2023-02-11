// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

interface IAgencyNFT {
  function tokenExists(uint256 tokenId) external view returns (bool);

  function ownerOf(uint256 tokenId) external view returns (address);

  function adminTransferToken(uint256 tokenId, address receiver) external;
}