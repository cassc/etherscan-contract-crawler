// SPDX-License-Identifier: MIT LICENSE 

pragma solidity ^0.8.0;

interface ISafari {
  function addManyToSafariAndPack(address account, uint16[] calldata tokenIds) external;
  function randomLionOwner(uint256 seed) external view returns (address);
}