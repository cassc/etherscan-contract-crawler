//SPDX-License-Identifier: MIT
pragma solidity >=0.5.0 <0.9.0;

/**
 * @title IHasPriceAccumulator
 * @notice An interface that defines a contract containing price accumulator.
 */
interface IHasPriceAccumulator {
    /// @notice Gets the address of the price accumulator.
    /// @return pa The address of the price accumulator.
    function priceAccumulator() external view returns (address pa);
}