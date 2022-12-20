// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ILendingPoolAddressesProvider} from 'aave-address-book/AaveV2Ethereum.sol';

/**
 * @title AaveV2ZeroInterestRateStrategy
 * @notice Aave v2 interest rate strategy, with all parameters zeroed
 * @dev In order to keep same assumptions on external getters, we keep the
 * initialization on the constructor of `addressesProvider`, even if in practise
 * is not really used.
 * Not implementing any interface because the one on protocol-v2 was already incomplete,
 * but respecting all functions on `DefaultReserveInterestRateStrategy`
 * @author BGD Labs
 */
contract AaveV2ZeroInterestRateStrategy {
  ILendingPoolAddressesProvider public immutable addressesProvider;

  /// @dev We replace all the externally exposed functions with constants, returning explicit zeroes
  uint256 public constant OPTIMAL_UTILIZATION_RATE = 0;
  uint256 public constant EXCESS_UTILIZATION_RATE = 0;
  uint256 public constant baseVariableBorrowRate = 0;
  uint256 public constant variableRateSlope1 = 0;
  uint256 public constant variableRateSlope2 = 0;
  uint256 public constant stableRateSlope1 = 0;
  uint256 public constant stableRateSlope2 = 0;
  uint256 public constant getMaxVariableBorrowRate = 0;

  constructor(ILendingPoolAddressesProvider provider) {
    addressesProvider = provider;
  }

  function calculateInterestRates(
    address,
    address,
    uint256,
    uint256,
    uint256,
    uint256,
    uint256,
    uint256
  )
    external
    pure
    returns (
      uint256,
      uint256,
      uint256
    )
  {
    return (0, 0, 0);
  }

  function calculateInterestRates(
    address,
    uint256,
    uint256,
    uint256,
    uint256,
    uint256
  )
    external
    pure
    returns (
      uint256,
      uint256,
      uint256
    )
  {
    return (0, 0, 0);
  }
}