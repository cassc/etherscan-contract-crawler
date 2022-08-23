//SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.9;

/// @title Interface for VaultManager
interface IVaultManager {
  event LogAddStrategy(address indexed strategy);
  event LogRemoveStrategy(address indexed strategy);

  function addStrategy(address strategy) external returns(bool);
  function removeStrategy(address strategy) external returns(bool);
  function checkStrategy(address strategy) external view returns(bool);
  function getStrategyLength() external view returns (uint256);
  function getStrategyIndex(uint256 strategyIndex)
        external
        view
        returns (address strategy);
  function getAllStrategies() external view returns (address[] memory);
}