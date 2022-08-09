// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

import "../interfaces/IERC20.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "../AnteTest.sol";

// Ante Test to check DAI remains +- 5% of USD
contract AnteDaiPegTest is AnteTest("DAI is pegged to USD") {
    // https://etherscan.io/token/0x6b175474e89094c44da98b954eedeac495271d0f
    address public constant DaiAddr = 0x6B175474E89094C44Da98b954EedeAC495271d0F;

    AggregatorV3Interface internal priceFeed;

    /**
     * Network: Mainnet
     * Aggregator: DAI/USD
     * Address: 0xAed0c38402a5d19df6E4c03F4E2DceD6e29c1ee9
     */
    constructor() {
        protocolName = "DAI";
        testedContracts = [DaiAddr];
        priceFeed = AggregatorV3Interface(0xAed0c38402a5d19df6E4c03F4E2DceD6e29c1ee9);
    }

    function checkTestPasses() public view override returns (bool) {
        (, int256 price, , , ) = priceFeed.latestRoundData();
        return (95000000 < price && price < 105000000);
    }
}