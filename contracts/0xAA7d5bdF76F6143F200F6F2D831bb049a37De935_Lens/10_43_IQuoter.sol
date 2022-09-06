// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "./ILensBase.sol";

/**
 * @dev There's two quoting methods available in this contract.
 * 1. Call "swap" in Hub contract, then throw an error to revert the swap.
 * 2. Fetch data from hub and simulate the swap in this contract.
 *
 * The former guarantees correctness and can estimate the gas cost of the swap.
 * The latter can generate a more detailed result, e.g. the input and output amounts for each tier.
 */
interface IQuoter is ILensBase {
    /// @notice Quote a single-hop swap
    function quoteSingle(
        address tokenIn,
        address tokenOut,
        uint256 tierChoices,
        int256 amountDesired
    )
        external
        returns (
            uint256 amountIn,
            uint256 amountOut,
            uint256 gasUsed
        );

    /// @notice Quote a swap
    function quote(bytes calldata path, int256 amountDesired)
        external
        returns (
            uint256 amountIn,
            uint256 amountOut,
            uint256 gasUsed
        );

    /// @notice Simulation result of a hop
    struct Hop {
        uint256 amountIn;
        uint256 amountOut;
        uint256 protocolFeeAmt;
        uint256[] tierAmountsIn;
        uint256[] tierAmountsOut;
        uint256[] tierData;
    }

    /// @notice Simulate a single-hop swap
    function simulateSingle(
        address tokenIn,
        address tokenOut,
        uint256 tierChoices,
        int256 amountDesired
    ) external view returns (Hop memory hop);

    /// @notice Simulate a swap
    function simulate(bytes calldata path, int256 amountDesired)
        external
        view
        returns (
            uint256 amountIn,
            uint256 amountOut,
            Hop[] memory hops
        );
}