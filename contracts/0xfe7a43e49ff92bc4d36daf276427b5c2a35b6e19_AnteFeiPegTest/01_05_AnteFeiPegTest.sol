// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../interfaces/IERC20.sol";
import "../AnteTest.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

// Ante Test to check USDC remains > 0.90
contract AnteFeiPegTest is AnteTest("Fei is above 90 cents on the dollar") {
    // https://etherscan.io/token/0x956F47F50A910163D8BF957Cf5846D573E7f87CA
    address public constant FeiAddr = 0x956F47F50A910163D8BF957Cf5846D573E7f87CA;

    AggregatorV3Interface internal priceFeed;

    int256 private preCheckPrice = 0;
    uint256 private preCheckBlock = 0;

    /**
     * Network: Mainnet
     * Aggregator: FEI/USD
     * Address: 0x31e0a88fecB6eC0a411DBe0e9E76391498296EE9
     */
    constructor() {
        protocolName = "Fei";
        testedContracts = [FeiAddr];
        priceFeed = AggregatorV3Interface(0x31e0a88fecB6eC0a411DBe0e9E76391498296EE9);
    }

    /// @notice Must be called 300-400 blocks (1hr) blocks before calling checkTestPasses to prevent flash loan attacks
    /// @notice Chainlink datafeeds trigger on a 1% difference. A flash loan attack will allow an asset to recover
    /// @notice within 1 hour.
    /// @dev Can only be called once 800 blocks to prevent spam reloading
    function preCheck() public {
        require(block.number - preCheckBlock > 800, "Precheck can only be called every 800 blocks");
        (, preCheckPrice, , , ) = priceFeed.latestRoundData();
        preCheckBlock = block.number;
    }

    /// @return true if the test will work properly (ie preCheck() was called 300 block prior)
    function willTestWork() public view returns (bool) {
        if (preCheckPrice == 0 || preCheckBlock == 0) return false;
        if (block.number - preCheckBlock < 300) return false;

        return true;
    }

    /// @notice Must call preCheck() 300 blocks prior to calling
    /// @return true if FEI is above 90 cents on the dollar
    function checkTestPasses() public view override returns (bool) {
        if (preCheckPrice == 0 || preCheckBlock == 0) return true;
        if (block.number - preCheckBlock < 300) return true;

        (, int256 price, , , ) = priceFeed.latestRoundData();
        return (90000000 < price) || (90000000 < preCheckPrice);
    }
}