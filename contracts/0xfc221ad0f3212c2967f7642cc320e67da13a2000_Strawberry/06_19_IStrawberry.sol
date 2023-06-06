// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol';

// Public interface for Strawberry.wtf contract
interface IStrawberry is IERC721Enumerable {
  // Set the seed phrase for the generation of Strawberries
  function setSeed(string memory seedString) external;

  // Set the proof hash
  function setProof(string memory proofString) external;

  // Set the if purchase and minting is active
  function setActive(bool isActive) external;

  // Set if the tokens are revealed
  function setTokensRevealed(bool tokensRevealed) external;

  // Purchase a single token
  function purchase(uint256 numberOfTokens) external payable;

  // Gift a single token
  function gift(address to) external payable;

  // Withdraw contract balance
  function withdraw() external;
}