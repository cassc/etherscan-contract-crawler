// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.9;

import {ISynthereumFinder} from '../../core/interfaces/IFinder.sol';
import {
  ISynthereumLendingRewards
} from '../common/interfaces/ILendingRewards.sol';
import {
  ILendingManager
} from '../../lending-module/interfaces/ILendingManager.sol';
import {
  ILendingStorageManager
} from '../../lending-module/interfaces/ILendingStorageManager.sol';
import {Address} from '../../../@openzeppelin/contracts/utils/Address.sol';
import {SynthereumMultiLpLiquidityPoolLib} from './MultiLpLiquidityPoolLib.sol';
import {SynthereumMultiLpLiquidityPool} from './MultiLpLiquidityPool.sol';

/**
 * @title Multi LP Synthereum pool with lending protocol rewards
 */
contract SynthereumMultiLpLiquidityPoolWithRewards is
  ISynthereumLendingRewards,
  SynthereumMultiLpLiquidityPool
{
  using Address for address;

  string private constant CLAIM_REWARDS_SIG =
    'claimRewards(bytes,address,address,address)';

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
  ) external override {
    ISynthereumFinder finderContract = finder;
    ILendingManager lendingManager =
      SynthereumMultiLpLiquidityPoolLib._getLendingManager(finderContract);
    require(
      msg.sender == address(lendingManager),
      'Sender must be the lending manager'
    );

    require(
      _poolLendingStorage.collateralToken ==
        address(storageParams.collateralAsset),
      'Wrong collateral passed'
    );
    address interestToken =
      SynthereumMultiLpLiquidityPoolLib
        ._getLendingStorageManager(finderContract)
        .getInterestBearingToken(address(this));
    require(
      _poolLendingStorage.interestToken == interestToken,
      'Wrong bearing token passed'
    );
    address(_lendingInfo.lendingModule).functionDelegateCall(
      abi.encodeWithSignature(
        CLAIM_REWARDS_SIG,
        _lendingInfo.args,
        _poolLendingStorage.collateralToken,
        _poolLendingStorage.interestToken,
        _recipient
      )
    );
  }
}