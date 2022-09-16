// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity >=0.8.13;

import "./IPriceOracle.sol";

/// @title Uniswap price oracle interface
/// @notice Contains logic for price calculation of asset using Uniswap V2 Pair
interface IUniswapV2PriceOracle is IPriceOracle {
    /// @notice Sets minimum update interval for oracle
    /// @param _minUpdateInterval Minimum update interval for oracle
    function setMinUpdateInterval(uint _minUpdateInterval) external;

    /// @notice Minimum oracle update interval
    /// @dev If min update interval hasn't passed before update, previously cached value is returned
    /// @return Minimum update interval in seconds
    function minUpdateInterval() external view returns (uint);

    /// @notice Asset0 in the pair
    /// @return Address of asset0 in the pair
    function asset0() external view returns (address);

    /// @notice Asset1 in the pair
    /// @return Address of asset1 in the pair
    function asset1() external view returns (address);
}