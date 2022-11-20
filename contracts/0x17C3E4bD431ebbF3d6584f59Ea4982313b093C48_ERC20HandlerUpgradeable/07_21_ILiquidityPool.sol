// SPDX-License-Identifier: MIT
pragma solidity >=0.8.2;

/// @title Interface for handler contracts that support deposits and deposit executions.
/// @author Router Protocol.
interface ILiquidityPool {
    /// @notice Staking should be done by using bridge contract.
    /// @param depositor stakes liquidity in the pool .
    /// @param tokenAddress staking token for which liquidity needs to be added.
    /// @param amount Amount that needs to be staked.
    function stake(
        address depositor,
        address tokenAddress,
        uint256 amount
    ) external;

    /// @notice Staking should be done by using bridge contract.
    /// @param depositor stakes liquidity in the pool .
    /// @param tokenAddress staking token for which liquidity needs to be added.
    /// @param amount Amount that needs to be staked.
    function stakeETH(
        address depositor,
        address tokenAddress,
        uint256 amount
    ) external;

    /// @notice Staking should be done by using bridge contract.
    /// @param unstaker removes liquidity from the pool.
    /// @param tokenAddress staking token of which liquidity needs to be removed.
    /// @param amount Amount that needs to be unstaked.
    function unstake(
        address unstaker,
        address tokenAddress,
        uint256 amount
    ) external;

    /// @notice Staking should be done by using bridge contract.
    /// @param unstaker removes liquidity from the pool.
    /// @param tokenAddress staking token of which liquidity needs to be removed.
    /// @param amount Amount that needs to be unstaked.
    function unstakeETH(
        address unstaker,
        address tokenAddress,
        uint256 amount
    ) external;
}