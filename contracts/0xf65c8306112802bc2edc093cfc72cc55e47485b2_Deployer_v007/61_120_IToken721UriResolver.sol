// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
  @notice
  Intended to serve custom ERC721 token URIs.
 */
interface IToken721UriResolver {
  function tokenURI(uint256) external view returns (string memory);
}