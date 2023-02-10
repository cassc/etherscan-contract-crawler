// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

import "../interfaces/IERC20.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "../AnteTest.sol";

// Ante Test to check BUSD remains +- 5% of USD
contract AnteBusdPegTest is AnteTest("BUSD is pegged to +- 5% of USD") {
    // https://etherscan.io/token/0x4Fabb145d64652a948d72533023f6E7A623C7C53
    address public constant BusdAddr = 0x4Fabb145d64652a948d72533023f6E7A623C7C53;

    AggregatorV3Interface internal priceFeed;

    /**
     * Network: Mainnet
     * Aggregator: BUSD/USD
     * Address: 0x833D8Eb16D306ed1FbB5D7A2E019e106B960965A
     */
    constructor() {
        protocolName = "BUSD";
        testedContracts = [BusdAddr];
        priceFeed = AggregatorV3Interface(0x833D8Eb16D306ed1FbB5D7A2E019e106B960965A);
    }

    function checkTestPasses() public view override returns (bool) {
        (, int256 price, , , ) = priceFeed.latestRoundData();
        return (95000000 < price && price < 105000000);
    }
}