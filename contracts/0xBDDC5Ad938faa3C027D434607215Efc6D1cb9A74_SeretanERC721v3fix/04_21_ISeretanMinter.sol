// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

interface ISeretanMinter {
  struct Phase {
    uint256 startTime;
    bytes32 allowlistRoot;
    uint256 maxNumberOfMinted;
    uint256 price;
  }

  function setPhaseList(address collection, Phase[] calldata phaseList) external;
}