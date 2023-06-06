// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Public interface for BigFarmer contract
interface IBigFarmer {
  // Returns if address is a Big Farmer
  function isBigFarmer(address sender) external view returns (bool);

  // Returns total number of Big Farmers
  function totalBigFarmers() external view returns (uint256);

  // Returns address of Big Farmer by index
  function bigFarmerByIndex(uint256 bigFarmerIndex) external view returns (address);
}