// SPDX-License-Identifier: MIT
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Holdings, 2023
pragma solidity ^0.8.17;

import {IAdapter} from "../IAdapter.sol";

/// @title Convex V1 BaseRewardPool adapter interface
/// @notice Implements logic for interacting with Convex reward pool
interface IConvexV1BaseRewardPoolAdapter is IAdapter {
    /// @notice Address of a Curve LP token deposited into the Convex pool
    function curveLPtoken() external view returns (address);

    /// @notice Address of a Convex LP token staked in the reward pool
    function stakingToken() external view returns (address);

    /// @notice Address of a phantom token representing account's stake in the reward pool
    function stakedPhantomToken() external view returns (address);

    /// @notice Collateral token mask of a Curve LP token in the credit manager
    function curveLPTokenMask() external view returns (uint256);

    /// @notice Collateral token mask of a Convex LP token in the credit manager
    function stakingTokenMask() external view returns (uint256);

    /// @notice Collateral token mask of a reward pool stake token
    function stakedTokenMask() external view returns (uint256);

    /// @notice Bitmask of all reward tokens of the pool (CRV, CVX, extra reward tokens, if any) in the credit manager
    function rewardTokensMask() external view returns (uint256);

    /// @notice Stakes Convex LP token in the reward pool
    /// @dev `amount` parameter is ignored since calldata is passed directly to the target contract
    function stake(uint256) external;

    /// @notice Stakes the entire balance of Convex LP token in the reward pool, disables LP token
    function stakeAll() external;

    /// @notice Claims rewards on the current position, enables reward tokens
    function getReward() external;

    /// @notice Withdraws Convex LP token from the reward pool
    /// @param claim Whether to claim staking rewards
    /// @dev `amount` parameter is ignored since calldata is passed directly to the target contract
    function withdraw(uint256, bool claim) external;

    /// @notice Withdraws the entire balance of Convex LP token from the reward pool, disables staked token
    /// @param claim Whether to claim staking rewards
    function withdrawAll(bool claim) external;

    /// @notice Withdraws Convex LP token from the reward pool and unwraps it into Curve LP token
    /// @param claim Whether to claim staking rewards
    /// @dev `amount` parameter is ignored since calldata is passed directly to the target contract
    function withdrawAndUnwrap(uint256, bool claim) external;

    /// @notice Withdraws the entire balance of Convex LP token from the reward pool and unwraps it into Curve LP token,
    ///         disables staked token
    /// @param claim Whether to claim staking rewards
    function withdrawAllAndUnwrap(bool claim) external;
}