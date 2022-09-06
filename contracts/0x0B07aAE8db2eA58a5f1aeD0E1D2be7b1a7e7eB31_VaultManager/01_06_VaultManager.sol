//SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "./interfaces/IVaultManager.sol";
import "./interfaces/ISWNFT.sol";

contract VaultManager is IVaultManager, Ownable {
  using EnumerableSet for EnumerableSet.AddressSet;
  EnumerableSet.AddressSet private strategiesSet;

    /// @notice Add a new strategy
    /// @param strategy The strategy address to add
    function addStrategy(address strategy) external onlyOwner returns (bool added) {
      require(strategy != address(0), "InvalidAddress");
      added = strategiesSet.add(strategy);
      if (added) {
          emit LogAddStrategy(strategy);
      }
    }

    /// @notice Remove a strategy
    /// @param strategy The strategy address to remove
    function removeStrategy(address strategy) external onlyOwner returns (bool removed) {
        removed = strategiesSet.remove(strategy);
        if (removed) {
            emit LogRemoveStrategy(strategy);
        }
    }

    function checkStrategy(address strategy) external view returns(bool) {
      return strategiesSet.contains(strategy);
    }

    /// @notice Get the length of the strategies
    /// @return length The length of the strategies
    function getStrategyLength() external view returns (uint256 length) {
        return strategiesSet.length();
    }

    function getStrategyIndex(uint256 strategyIndex)
        external
        view
        returns (address strategy)
    {
      require(strategyIndex < strategiesSet.length(), "Index out");
      return strategiesSet.at(strategyIndex);
    }

    function getAllStrategies() external view returns (address[] memory) {
        return strategiesSet.values();
    }

    modifier onlyValidStrategy(address strategy) {
      require(strategiesSet.contains(strategy), "Inv strategy");  
      _;    
    }
}