// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.17;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "./IMToken.sol";
import "./IPriceOracle.sol";

interface IChainlinkPriceOracle is IPriceOracle {
    event NewTokenConfigSet(
        address token,
        address oracleAddress,
        uint8 underlyingTokenDecimals,
        uint8 reporterMultiplier,
        uint32 timestampThreshold
    );

    /**
     * @notice Return config for token
     */
    function feedProxies(address)
        external
        view
        returns (
            AggregatorV3Interface chainlinkAggregator,
            uint8 underlyingTokenDecimals,
            uint8 reporterMultiplier,
            uint32 timestampThreshold
        );

    /**
     * @notice Set the proxy of a underlying asset
     * @param token The underlying to set the price oracle proxy of
     * @param oracleAddress Address of corresponding oracle
     * @param underlyingTokenDecimals Original token decimals
     * @param reporterMultiplier Constant, using for decimal cast from decimals,
                                  returned by oracle to required decimals.
     * @param timestampThreshold  max threshold for oracle validation
     * @dev reporterMultiplier = 8 + underlyingDecimals - feedDecimals
     * @dev RESTRICTION: Admin only
     */
    function setTokenConfig(
        address token,
        address oracleAddress,
        uint8 underlyingTokenDecimals,
        uint8 reporterMultiplier,
        uint32 timestampThreshold
    ) external;
}