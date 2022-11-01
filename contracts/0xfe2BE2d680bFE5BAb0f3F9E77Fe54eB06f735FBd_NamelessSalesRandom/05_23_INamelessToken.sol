// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
interface INamelessToken {
  event TokenMetadataChanged(uint256 tokenId);
  event TokenRedeemed(uint256 tokenId, uint256 timestamp, string memo);

  function initialize(string memory name, string memory symbol, address tokenDataContract, address initialAdmin) external;
}