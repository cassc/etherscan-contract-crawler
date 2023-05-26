// SPDX-License-Identifier: MIT
pragma solidity 0.8.3;

import '../libraries/DataStruct.sol';

interface IConnector {
  /**
   * @notice Emitted when an admin adds a council role
   **/
  event NewCouncilAdded(address indexed account);

  /**
   * @notice Emitted when an admin adds a collateral service provider role
   **/
  event NewCollateralServiceProviderAdded(address indexed account);

  /**
   * @notice Emitted when a council role is revoked by admin
   **/
  event CouncilRevoked(address indexed account);

  /**
   * @notice Emitted when a collateral service provider role is revoked by admin
   **/
  event CollateralServiceProviderRevoked(address indexed account);

  function isCollateralServiceProvider(address account) external view returns (bool);

  function isCouncil(address account) external view returns (bool);

  function isMoneyPoolAdmin(address account) external view returns (bool);
}