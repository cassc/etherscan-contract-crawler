//SPDX-License-Identifier: MIT
pragma solidity >=0.5.0 <0.9.0;

/**
 * @title IHasLiquidityAccumulator
 * @notice An interface that defines a contract containing liquidity accumulator.
 */
interface IHasLiquidityAccumulator {
    /// @notice Gets the address of the liquidity accumulator.
    /// @return la The address of the liquidity accumulator.
    function liquidityAccumulator() external view returns (address la);
}