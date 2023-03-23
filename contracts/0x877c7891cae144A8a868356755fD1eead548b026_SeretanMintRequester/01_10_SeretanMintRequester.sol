// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "./SeretanMinterFix2.sol";

contract SeretanMintRequester {
  function requestMint(
    uint256 batchSize,
    address minter,
    uint256 value,
    address collection,
    address to,
    uint256 currentPhaseNumber,
    bytes32[] calldata allowlistProof,
    uint256 maxNumberOfMintedToDest
  )
    public
    payable
  {
    for (uint256 i = 0; i < batchSize; i++) {
        SeretanMinterFix2(minter).mint{value: value}(collection, to, currentPhaseNumber, allowlistProof, maxNumberOfMintedToDest);
    }
  }
}