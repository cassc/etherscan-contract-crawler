// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {DataTypes} from '../libraries/types/DataTypes.sol';

interface ILendingPool {
  function deposit(address asset, uint256 amount, address onBehalfOf, uint16 referralCode) external;
  function borrow(address asset, uint256 amount, uint256 interestRateMode, uint16 referralCode, address onBehalfOf) external;
  function getConfiguration(address asset) external view returns (DataTypes.ReserveConfigurationMap memory);
  function getReserveData(address asset) external view returns (DataTypes.ReserveData memory);
  function getReservesList() external view returns (address[] memory);
}