// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

interface IMetadataResolver {
  function tokenUri(address contractAddress, uint256 tokenId) external view returns (string memory);
}