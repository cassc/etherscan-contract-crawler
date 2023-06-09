/**
 * IMPORTANT: THIS CONTRACT IS A COPY FROM ERC712 CONTRACT TO RUN IT LOCALLY
 * DO NOT DEPLOY THIS CONTRACT IN MAINNET, IF YOU WANT THE ORIGINAL CODE
 * CHECK IT HERE: https://github.com/harmvandendorpel/maschine-token-contract
 */

//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface INFT {
  function tokenIdMax() external view returns (uint16);

  function currentTokenId() external view returns (uint256);

  function mint(address to) external;
}