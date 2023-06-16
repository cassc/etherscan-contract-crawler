// SPDX-License-Identifier: MIT
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Holdings, 2023
pragma solidity ^0.8.17;

import {IAdapter} from "../IAdapter.sol";

interface ICurveV1AdapterExceptions {
    /// @notice Thrown when trying to pass incorrect asset index as parameter to an adapter function
    error IncorrectIndexException();
}

/// @title Curve V1 base adapter interface
/// @notice Implements logic allowing to interact with all Curve pools, regardless of number of coins
interface ICurveV1Adapter is IAdapter, ICurveV1AdapterExceptions {
    /// @notice Exchanges one pool asset to another
    /// @param i Index of the asset to spend
    /// @param j Index of the asset to receive
    /// @dev `dx` and `min_dy` parameters are ignored because calldata is passed directly to the target contract
    function exchange(int128 i, int128 j, uint256, uint256) external;

    /// @notice `exchange` wrapper to support newer pools which accept uint256 for token indices
    function exchange(uint256 i, uint256 j, uint256, uint256) external;

    /// @notice Exchanges the entire balance of one pool asset to another, disables input asset
    /// @param i Index of the asset to spend
    /// @param j Index of the asset to receive
    /// @param rateMinRAY Minimum exchange rate between assets i and j, scaled by 1e27
    function exchange_all(int128 i, int128 j, uint256 rateMinRAY) external;

    /// @notice `exchange_all` wrapper to support newer pools which accept uint256 for token indices
    function exchange_all(uint256 i, uint256 j, uint256 rateMinRAY) external;

    /// @notice Exchanges one pool's underlying asset to another
    /// @param i Index of the underlying asset to spend
    /// @param j Index of the underlying asset to receive
    /// @dev `dx` and `min_dy` parameters are ignored because calldata is passed directly to the target contract
    function exchange_underlying(int128 i, int128 j, uint256, uint256) external;

    /// @notice `exchange_underlying` wrapper to support newer pools which accept uint256 for token indices
    function exchange_underlying(uint256 i, uint256 j, uint256, uint256) external;

    /// @notice Exchanges the entire balance of one pool's underlying asset to another, disables input asset
    /// @param i Index of the underlying asset to spend
    /// @param j Index of the underlying asset to receive
    /// @param rateMinRAY Minimum exchange rate between underlying assets i and j, scaled by 1e27
    function exchange_all_underlying(int128 i, int128 j, uint256 rateMinRAY) external;

    /// @notice `exchange_all_underlying` wrapper to support newer pools which accept uint256 for token indices
    function exchange_all_underlying(uint256 i, uint256 j, uint256 rateMinRAY) external;

    /// @notice Adds given amount of asset as liquidity to the pool
    /// @param amount Amount to deposit
    /// @param i Index of the asset to deposit
    /// @param minAmount Minimum amount of LP tokens to receive
    function add_liquidity_one_coin(uint256 amount, int128 i, uint256 minAmount) external;

    /// @notice `add_liquidity_one_coin` wrapper to support newer pools which accept uint256 for token indices
    function add_liquidity_one_coin(uint256 amount, uint256 i, uint256 minAmount) external;

    /// @notice Adds the entire balance of asset as liquidity to the pool, disables this asset
    /// @param i Index of the asset to deposit
    /// @param rateMinRAY Minimum exchange rate between deposited asset and LP token, scaled by 1e27
    function add_all_liquidity_one_coin(int128 i, uint256 rateMinRAY) external;

    /// @notice `add_all_liquidity_one_coin` wrapper to support newer pools which accept uint256 for token indices
    function add_all_liquidity_one_coin(uint256 i, uint256 rateMinRAY) external;

    /// @notice Removes liquidity from the pool in a specified asset
    /// @param i Index of the asset to withdraw
    /// @dev `_token_amount` and `min_amount` parameters are ignored because calldata is passed directly to the target contract
    function remove_liquidity_one_coin(uint256, int128 i, uint256) external;

    /// @notice `remove_liquidity_one_coin` wrapper to support newer pools which accept uint256 for token indices
    function remove_liquidity_one_coin(uint256, uint256 i, uint256) external;

    /// @notice Removes all liquidity from the pool in a specified asset
    /// @param i Index of the asset to withdraw
    /// @param rateMinRAY Minimum exchange rate between LP token and received token, scaled by 1e27
    function remove_all_liquidity_one_coin(int128 i, uint256 rateMinRAY) external;

    /// @notice `remove_all_liquidity_one_coin` wrapper to support newer pools which accept uint256 for token indices
    function remove_all_liquidity_one_coin(uint256 i, uint256 rateMinRAY) external;

    /// @notice Pool LP token address (added for backward compatibility)
    function token() external view returns (address);

    /// @notice Pool LP token address
    function lp_token() external view returns (address);

    /// @notice Collateral token mask of pool LP token in the credit manager
    function lpTokenMask() external view returns (uint256);

    /// @notice Base pool address (for metapools only)
    function metapoolBase() external view returns (address);

    /// @notice Number of coins in the pool
    function nCoins() external view returns (uint256);

    /// @notice Whether to use uint256 for token indexes in write functions
    function use256() external view returns (bool);

    /// @notice Token in the pool under index 0
    function token0() external view returns (address);

    /// @notice Token in the pool under index 1
    function token1() external view returns (address);

    /// @notice Token in the pool under index 2
    function token2() external view returns (address);

    /// @notice Token in the pool under index 3
    function token3() external view returns (address);

    /// @notice Collateral token mask of token0 in the credit manager
    function token0Mask() external view returns (uint256);

    /// @notice Collateral token mask of token1 in the credit manager
    function token1Mask() external view returns (uint256);

    /// @notice Collateral token mask of token2 in the credit manager
    function token2Mask() external view returns (uint256);

    /// @notice Collateral token mask of token3 in the credit manager
    function token3Mask() external view returns (uint256);

    /// @notice Underlying in the pool under index 0
    function underlying0() external view returns (address);

    /// @notice Underlying in the pool under index 1
    function underlying1() external view returns (address);

    /// @notice Underlying in the pool under index 2
    function underlying2() external view returns (address);

    /// @notice Underlying in the pool under index 3
    function underlying3() external view returns (address);

    /// @notice Collateral token mask of underlying0 in the credit manager
    function underlying0Mask() external view returns (uint256);

    /// @notice Collateral token mask of underlying1 in the credit manager
    function underlying1Mask() external view returns (uint256);

    /// @notice Collateral token mask of underlying2 in the credit manager
    function underlying2Mask() external view returns (uint256);

    /// @notice Collateral token mask of underlying3 in the credit manager
    function underlying3Mask() external view returns (uint256);

    /// @notice Returns the amount of LP token received for adding a single asset to the pool
    /// @param amount Amount to deposit
    /// @param i Index of the asset to deposit
    function calc_add_one_coin(uint256 amount, int128 i) external view returns (uint256);

    /// @notice `calc_add_one_coin` wrapper to support newer pools which accept uint256 for token indices
    function calc_add_one_coin(uint256 amount, uint256 i) external view returns (uint256);
}