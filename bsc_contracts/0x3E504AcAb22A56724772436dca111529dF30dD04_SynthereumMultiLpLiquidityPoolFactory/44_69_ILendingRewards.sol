// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import {
  ILendingStorageManager
} from '../../../lending-module/interfaces/ILendingStorageManager.sol';

/**
 * @title Pool interface for claiming lending rewards
 */
interface ISynthereumLendingRewards {
  /**
   * @notice Claim rewards, associaated to the lending module supported by the pool
   * @notice Only the lending manager can call the function
   * @param _lendingInfo Address of lending module implementation and global args
   * @param _poolLendingStorage Addresses of collateral and bearing token of the pool
   * @param _recipient Address of recipient receiving rewards
   */
  function claimLendingRewards(
    ILendingStorageManager.LendingInfo calldata _lendingInfo,
    ILendingStorageManager.PoolLendingStorage calldata _poolLendingStorage,
    address _recipient
  ) external;
}