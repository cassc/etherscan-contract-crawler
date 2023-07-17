// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

import "../interfaces/IERC20.sol";
import "../AnteTest.sol";
import "hardhat/console.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

interface IRedemptionPriceSnap {
    // Return the lastest redemption price snap
    function snappedRedemptionPrice() external view returns (uint256);
}

library Math {
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
}

// Ante Test to check RAI redemption rate with 10% of CL oracle price
contract AnteRaiRedemptionTest is AnteTest("RAI redemption vs Chainlink oracle within 10 percent") {
    // https://etherscan.io/token/0x03ab458634910aad20ef5f1c8ee96f1d6ac54919
    address public constant RaiAddr = 0x03ab458634910AaD20eF5f1C8ee96F1D6ac54919;

    // https://etherscan.io/address/0x07210B8871073228626AB79c296d9b22238f63cE
    address public constant snapAddr = 0x07210B8871073228626AB79c296d9b22238f63cE;

    // The redemption rate is 27 decimals, the CL feed is 8 decimals, using difference to compare
    uint256 public constant DECIMALS = 19;

    // Allowed deviation
    uint256 public constant ERROR_PERCENT = 10;

    AggregatorV3Interface internal priceFeed;
    IRedemptionPriceSnap internal redemptionPrice = IRedemptionPriceSnap(snapAddr);

    /**
     * Network: Mainnet
     * Aggregator: RAI/USD
     * Address: 0x483d36f6a1d063d580c7a24f9a42b346f3a69fbb
     */
    constructor() {
        protocolName = "RAI";
        testedContracts = [RaiAddr];
        priceFeed = AggregatorV3Interface(0x483d36F6a1d063d580c7a24F9A42B346f3a69fbb);
    }

    function checkTestPasses() public view override returns (bool) {
        (, int256 price, , , ) = priceFeed.latestRoundData();
        uint256 clPrice = uint256(price);
        uint256 redPrice = redemptionPrice.snappedRedemptionPrice() / 10**DECIMALS;
        uint256 difference = Math.max(clPrice, redPrice) - Math.min(clPrice, redPrice);
        return (difference < redPrice / ERROR_PERCENT);
    }
}