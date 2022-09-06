// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity >=0.8.13;

import "./IPriceOracle.sol";

/// @title Chainlink price oracle interface
/// @notice Extends IPriceOracle interface
interface IChainlinkPriceOracle is IPriceOracle {
    event AssetAdded(address _asset, address[] _aggregators);
    event SetMaxUpdateInterval(address _account, uint _maxUpdateInterval);

    /// @notice Adds `_asset` to the oracle
    /// @param _asset Asset's address
    /// @param _assetAggregator Asset aggregator address
    function addAsset(address _asset, address _assetAggregator) external;

    /// @notice Adds `_asset` to the oracle
    /// @param _asset Asset's address
    /// @param _assetAggregators Asset aggregators addresses
    function addAsset(address _asset, address[] memory _assetAggregators) external;

    /// @notice Sets max update interval
    /// @param _maxUpdateInterval Max update interval
    function setMaxUpdateInterval(uint _maxUpdateInterval) external;

    /// @notice Max update interval
    /// @return Returns max update interval
    function maxUpdateInterval() external view returns (uint);
}