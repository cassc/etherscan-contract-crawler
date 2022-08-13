// SPDX-License-Identifier: MIT
// ERC721A Contracts v4.1.0
// Creator: Chiru Labs

pragma solidity ^0.8.4;

/**
 * @dev Interface of an ERC721A compliant contract.
 */
interface ICanvas {
  function mintCanvas(address to, uint amt) external;
  function teamMintCanvas(address to, uint amt) external;
  function transferCanvas(address from, address to, uint tokenId) external;
  //function setGreeting(string memory _greeting) external;
}