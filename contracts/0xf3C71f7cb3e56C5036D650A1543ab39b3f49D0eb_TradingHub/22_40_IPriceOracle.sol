// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.6.12;

/// @notice Interface of PriceOracle
interface IPriceOracle {
    enum PriceOracleMode {
        DEX_MODE,
        CHAINLINK_MODE,
        FEED_NODE
    }

    function getLatestMixinPrice(address tokenAddr) external view returns (uint256 tokenPrice, uint256 decimals);

    function getTokenPrice(address tokenAddr) external view returns (uint256 tokenPrice);
}