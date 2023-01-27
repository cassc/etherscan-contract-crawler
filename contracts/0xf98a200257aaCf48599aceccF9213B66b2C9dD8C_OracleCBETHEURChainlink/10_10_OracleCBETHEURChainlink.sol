// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.12;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

import "../../BaseOracleChainlinkMultiTwoFeeds.sol";

/// @title OracleCBETHEURChainlink
/// @author Angle Labs, Inc.
/// @notice Gives the price of cbETH in Euro in base 18
contract OracleCBETHEURChainlink is BaseOracleChainlinkMultiTwoFeeds {
    string public constant DESCRIPTION = "cbETH/EUR Oracle";

    constructor(uint32 _stalePeriod, address _treasury) BaseOracleChainlinkMultiTwoFeeds(_stalePeriod, _treasury) {}

    /// @inheritdoc IOracle
    function circuitChainlink() public pure override returns (AggregatorV3Interface[] memory) {
        AggregatorV3Interface[] memory _circuitChainlink = new AggregatorV3Interface[](3);
        // Oracle cbETH/ETH
        _circuitChainlink[0] = AggregatorV3Interface(0xF017fcB346A1885194689bA23Eff2fE6fA5C483b);
        // Oracle ETH/USD
        _circuitChainlink[1] = AggregatorV3Interface(0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419);
        // Oracle EUR/USD
        _circuitChainlink[2] = AggregatorV3Interface(0xb49f677943BC038e9857d61E7d053CaA2C1734C1);
        return _circuitChainlink;
    }

    /// @inheritdoc BaseOracleChainlinkMultiTwoFeeds
    function read() external view virtual override returns (uint256 quoteAmount) {
        quoteAmount = _getQuoteAmount();
        AggregatorV3Interface[] memory _circuitChainlink = circuitChainlink();
        uint8[3] memory circuitChainIsMultiplied = [1, 1, 0];
        uint8[3] memory chainlinkDecimals = [18, 8, 8];
        uint256 circuitLength = _circuitChainlink.length;
        for (uint256 i; i < circuitLength; ++i) {
            quoteAmount = _readChainlinkFeed(
                quoteAmount,
                _circuitChainlink[i],
                circuitChainIsMultiplied[i],
                chainlinkDecimals[i]
            );
        }
    }
}