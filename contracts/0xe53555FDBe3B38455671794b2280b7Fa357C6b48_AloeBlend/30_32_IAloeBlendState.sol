// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";

interface IAloeBlendState {
    /**
     * @notice A variety of key parameters used frequently in the vault's code, stored in a single slot to save gas
     * @dev If lower and upper bounds of a Uniswap position are equal, then the vault hasn't deposited liquidity to it
     * @return primaryLower The primary position's lower tick bound
     * @return primaryUpper The primary position's upper tick bound
     * @return limitLower The limit order's lower tick bound
     * @return limitUpper The limit order's upper tick bound
     * @return recenterTimestamp The `block.timestamp` from the last time the primary position moved
     * @return maxRebalanceGas The (approximate) maximum amount of gas that has ever been used to `rebalance()` this vault
     * @return maintenanceIsSustainable Whether `maintenanceBudget0` or `maintenanceBudget1` has filled up according to `K`
     * @return locked Whether the vault is currently locked to reentrancy
     */
    function packedSlot()
        external
        view
        returns (
            int24 primaryLower,
            int24 primaryUpper,
            int24 limitLower,
            int24 limitUpper,
            uint48 recenterTimestamp,
            uint32 maxRebalanceGas,
            bool maintenanceIsSustainable,
            bool locked
        );

    /// @notice The amount of token0 that was in silo0 last time maintenanceBudget0 was updated
    function silo0Basis() external view returns (uint256);

    /// @notice The amount of token1 that was in silo1 last time maintenanceBudget1 was updated
    function silo1Basis() external view returns (uint256);

    /// @notice The amount of token0 available for `rebalance()` rewards
    function maintenanceBudget0() external view returns (uint256);

    /// @notice The amount of token1 available for `rebalance()` rewards
    function maintenanceBudget1() external view returns (uint256);

    /**
     * @notice The contract's opinion on the fair value of 1e4 units of gas, denominated in `_token`
     * @dev The value reported here is an average over 14 samples. Nominally there is 1 sample per day, but actual
     * timing isn't stored. Please do not use this as more than a low fidelity approximation/proxy for truth.
     * @param token The ERC20 token for which the average gas price should be retrieved
     * @return gasPrice The amount of `_token` that may motivate expenditure of 1e4 units of gas
     */
    function gasPrices(address token) external view returns (uint256 gasPrice);
}