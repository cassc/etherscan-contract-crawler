// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IFliesToken {
  function onStakeEvent(address addr, uint256[] calldata tokenIds) external;
  function onUnstakeEvent(address addr, uint256[] calldata tokenIds) external;
}