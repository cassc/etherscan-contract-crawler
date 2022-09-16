// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity >=0.8.13;

import "./IPriceOracle.sol";

/// @title Uniswap price oracle interface
/// @notice Contains logic for price calculation of asset using Uniswap V3 Pool
interface IUniswapV3PriceOracle is IPriceOracle {
    /// @notice Sets twap interval for oracle
    /// @param _twapInterval Twap interval for oracle
    function setTwapInterval(uint32 _twapInterval) external;

    /// @notice Twap oracle update interval
    /// @return Twap interval in seconds
    function twapInterval() external view returns (uint32);

    /// @notice Asset0 in the pair
    /// @return Address of asset0 in the pair
    function asset0() external view returns (address);

    /// @notice Asset1 in the pair
    /// @return Address of asset1 in the pair
    function asset1() external view returns (address);
}