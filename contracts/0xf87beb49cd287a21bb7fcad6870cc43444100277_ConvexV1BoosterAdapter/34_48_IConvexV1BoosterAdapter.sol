// SPDX-License-Identifier: MIT
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Holdings, 2023
pragma solidity ^0.8.17;

import {IAdapter} from "../IAdapter.sol";

/// @title Convex V1 Booster adapter interface
/// @notice Implements logic allowing CAs to interact with Convex Booster
interface IConvexV1BoosterAdapter is IAdapter {
    /// @notice Maps pool ID to phantom token representing staked position
    function pidToPhantomToken(uint256) external view returns (address);

    /// @notice Deposits Curve LP tokens into Booster
    /// @param _pid ID of the pool to deposit to
    /// @param _stake Whether to stake Convex LP tokens in the rewards pool
    /// @dev `_amount` parameter is ignored since calldata is passed directly to the target contract
    function deposit(uint256 _pid, uint256, bool _stake) external;

    /// @notice Deposits the entire balance of Curve LP tokens into Booster, disables Curve LP token
    /// @param _pid ID of the pool to deposit to
    /// @param _stake Whether to stake Convex LP tokens in the rewards pool
    function depositAll(uint256 _pid, bool _stake) external;

    /// @notice Withdraws Curve LP tokens from Booster
    /// @param _pid ID of the pool to withdraw from
    /// @dev `_amount` parameter is ignored since calldata is passed directly to the target contract
    function withdraw(uint256 _pid, uint256) external;

    /// @notice Withdraws all Curve LP tokens from Booster, disables Convex LP token
    /// @param _pid ID of the pool to withdraw from
    /// @dev `_amount` parameter is ignored since calldata is passed directly to the target contract
    function withdrawAll(uint256 _pid) external;

    /// @notice Updates the mapping of pool IDs to phantom staked token addresses
    function updateStakedPhantomTokensMap() external;
}