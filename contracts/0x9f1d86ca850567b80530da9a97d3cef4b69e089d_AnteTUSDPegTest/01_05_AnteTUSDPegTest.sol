// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../interfaces/IERC20.sol";
import "../AnteTest.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

/// @title Checks if TUSD is pegged to the US Dollar
/// @author 0xa0e7Fb16cdE37Ebf2ceD6C89fbAe8780B8497e12
contract AnteTUSDPegTest is AnteTest("TUSD is above 90 cents on the US Dollar") {
    // https://etherscan.io/address/0x0000000000085d4780B73119b644AE5ecd22b376
    address public constant trueUSDAddr = 0x0000000000085d4780B73119b644AE5ecd22b376;

    AggregatorV3Interface internal priceFeed;

    /**
     * Network: Ethereum Mainnet
     * Aggregator: TUSD/USD
     * Address: 0xec746eCF986E2927Abd291a2A1716c940100f8Ba
     */
    constructor() {
        protocolName = "TrueUSD";
        testedContracts = [trueUSDAddr];
        priceFeed = AggregatorV3Interface(0xec746eCF986E2927Abd291a2A1716c940100f8Ba);
    }

    /// @return true if price of TUSD remains above 90 cents
    function checkTestPasses() public view override returns (bool) {
        (, int256 price, , , ) = priceFeed.latestRoundData();
        return (90000000 < price);
    }
}