// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IClassicPool {
  function getCurrentExchangeRate() external view returns (uint256);

  function manager() external view returns (address);

  function currency() external view returns (address);
}