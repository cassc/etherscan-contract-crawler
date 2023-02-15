// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.12;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

import "../../../BaseOracleChainlinkMultiTwoFeeds.sol";

/// @title OracleETHXAUChainlink
/// @author Angle Labs, Inc.
/// @notice Gives the price of ETH in XAU in base 18
contract OracleETHXAUChainlink is BaseOracleChainlinkMultiTwoFeeds {
    string public constant DESCRIPTION = "ETH/GOLD Oracle";

    constructor(uint32 _stalePeriod, address _treasury) BaseOracleChainlinkMultiTwoFeeds(_stalePeriod, _treasury) {}

    /// @inheritdoc IOracle
    function circuitChainlink() public pure override returns (AggregatorV3Interface[] memory) {
        AggregatorV3Interface[] memory _circuitChainlink = new AggregatorV3Interface[](2);
        // Oracle ETH/USD
        _circuitChainlink[0] = AggregatorV3Interface(0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419);
        // Oracle XAU/USD
        _circuitChainlink[1] = AggregatorV3Interface(0x214eD9Da11D2fbe465a6fc601a91E62EbEc1a0D6);
        return _circuitChainlink;
    }
}