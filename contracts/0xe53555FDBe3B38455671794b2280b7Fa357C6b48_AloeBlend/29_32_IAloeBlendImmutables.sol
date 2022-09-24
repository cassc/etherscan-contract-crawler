// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./ISilo.sol";
import "./IVolatilityOracle.sol";

// solhint-disable func-name-mixedcase
interface IAloeBlendImmutables {
    /// @notice The nominal time (in seconds) that the primary Uniswap position should stay in one place before
    /// being recentered
    function RECENTERING_INTERVAL() external view returns (uint24);

    /// @notice The minimum width (in ticks) of the primary Uniswap position
    function MIN_WIDTH() external view returns (int24);

    /// @notice The maximum width (in ticks) of the primary Uniswap position
    function MAX_WIDTH() external view returns (int24);

    /// @notice The maintenance budget buffer multiplier
    /// @dev The vault will attempt to build up a maintenance budget equal to the average cost of rebalance
    /// incentivization, multiplied by K.
    function K() external view returns (uint8);

    /// @notice If the maintenance budget drops below [its maximum size ➗ this value], `maintenanceIsSustainable` will
    /// become false. During the next rebalance, this will cause the primary Uniswap position to expand to its maximum
    /// width -- de-risking the vault until it has time to rebuild the maintenance budget.
    function L() external view returns (uint8);

    /// @notice The number of standard deviations (from volatilityOracle) to +/- from mean when choosing
    /// range for primary Uniswap position
    function B() external view returns (uint8);

    /// @notice The constraint factor for new gas price observations. The new observation cannot be less than (1 - 1/D)
    /// times the previous average.
    function D() external view returns (uint8);

    /// @notice The denominator applied to all earnings to determine what portion goes to maintenance budget
    /// @dev For example, if this is 10, then *at most* 1/10th of all revenue will be added to the maintenance budget.
    function MAINTENANCE_FEE() external view returns (uint8);

    /// @notice The percentage of funds (in basis points) that will be left in the contract after the primary Uniswap
    /// position is recentered. If your share of the pool is <<< than this, withdrawals will be more gas efficient.
    /// Also makes it less gassy to place limit orders.
    function FLOAT_PERCENTAGE() external view returns (uint256);

    /// @notice The volatility oracle used to decide position width
    function volatilityOracle() external view returns (IVolatilityOracle);

    /// @notice The silo where excess token0 is stored to earn yield
    function silo0() external view returns (ISilo);

    /// @notice The silo where excess token1 is stored to earn yield
    function silo1() external view returns (ISilo);
}