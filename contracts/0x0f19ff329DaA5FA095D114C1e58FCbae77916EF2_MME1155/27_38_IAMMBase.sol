// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.10;

import {DataTypes} from "../libraries/DataTypes.sol";

/**
 * @title IAMMBase
 * @author Souq.Finance
 * @notice Defines the interface of the AMM Base.
 * @notice License: https://souq-nft-amm-v1.s3.amazonaws.com/LICENSE.md
 */
interface IAMMBase {
    /**
     * @dev Emitted when the pool fee changes
     * @param _newFee The new fee
     */
    event FeeChanged(DataTypes.PoolFee _newFee);

    /**
     * @dev Emitted when the Pool Data struct is changed
     * @param _data The new pool data
     */
    event PoolDataSet(DataTypes.PoolData _data);

    /**
     * @dev Emitted when the Pool Iterative limits are changed
     * @param _limits The new pool data limit
     */
    event PoolIterativeLimitsSet(DataTypes.IterativeLimit _limits);

    /**
     * @dev Emitted when the Pool Liquidity limits are changed
     * @param _limits The new pool data limit
     */
    event PoolLiquidityLimitsSet(DataTypes.LiquidityLimit _limits);

    /**
     * @dev Function to set the pool fee
     * @param _newFee The new fee struct
     */
    function setFee(DataTypes.PoolFee calldata _newFee) external;

    /**
     * @dev Function to set the Pool Iterative limits for the bonding curve
     * @param _newLimits The new limits struct
     */
    function setPoolIterativeLimits(DataTypes.IterativeLimit calldata _newLimits) external;

    /**
     * @dev Function to set the Pool liquidity limits for deposits and withdrawals of liquidity
     * @param _newLimits The new limits struct
     */
    function setPoolLiquidityLimits(DataTypes.LiquidityLimit calldata _newLimits) external;

    /**
     * @dev Function to set the Pool Data - for Beta Testing
     * @param _newPoolData the new pooldata struct
     */
    function setPoolData(DataTypes.PoolData calldata _newPoolData) external;
}