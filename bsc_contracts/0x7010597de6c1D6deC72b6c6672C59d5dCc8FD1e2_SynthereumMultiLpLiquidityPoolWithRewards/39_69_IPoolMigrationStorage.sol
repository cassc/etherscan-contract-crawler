// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.9;

import {IStandardERC20} from '../../../../base/interfaces/IStandardERC20.sol';
import {
  IMintableBurnableERC20
} from '../../../../tokens/interfaces/IMintableBurnableERC20.sol';
import {
  ISynthereumMultiLpLiquidityPool
} from '../../../v6/interfaces/IMultiLpLiquidityPool.sol';

/**
 * @title Interface containing the struct for storage encoding/decoding for each pool version
 */
interface ISynthereumPoolMigrationStorage {
  struct MigrationV6 {
    string lendingModuleId;
    bytes32 priceIdentifier;
    uint256 totalSyntheticAsset;
    IStandardERC20 collateralAsset;
    uint64 fee;
    uint8 collateralDecimals;
    uint128 overCollateralRequirement;
    uint64 liquidationBonus;
    IMintableBurnableERC20 syntheticAsset;
    address[] registeredLPsList;
    address[] activeLPsList;
    ISynthereumMultiLpLiquidityPool.LPPosition[] positions;
    address[] admins;
    address[] maintainers;
  }
}