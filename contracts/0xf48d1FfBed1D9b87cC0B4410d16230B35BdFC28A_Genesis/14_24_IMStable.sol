// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0 <0.7.0;

interface IMStable {
  // Nexus
  function getModule(bytes32) external view returns (address);

  // Savings Manager
  function savingsContracts(address) external view returns (address);

  // Savings Contract
  function exchangeRate() external view returns (uint256);

  function creditBalances(address) external view returns (uint256);

  function depositSavings(uint256) external;

  function redeem(uint256) external returns (uint256);
}