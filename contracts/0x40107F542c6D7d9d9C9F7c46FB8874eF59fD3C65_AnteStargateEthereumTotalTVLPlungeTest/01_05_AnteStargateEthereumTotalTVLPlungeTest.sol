// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {AnteTest} from "../AnteTest.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

// @title  Stargate TVL Plunge Test (Ethereum)
// @notice Ante Test to check that assets in Stargate pools on Ethereum
//         (currently USDT, USDC, ETH) do not plunge by 90% from the time of
//         test deploy
contract AnteStargateEthereumTotalTVLPlungeTest is AnteTest("Stargate TVL on Ethereum does not plunge by 90%") {
    address constant STARGATE_USDT_POOL = 0x38EA452219524Bb87e18dE1C24D3bB59510BD783;
    address constant STARGATE_USDC_POOL = 0xdf0770dF86a8034b3EFEf0A1Bb3c889B8332FF56;
    address constant STARGATE_SGETH_POOL = 0x101816545F6bd2b1076434B54383a1E633390A2E;

    IERC20 constant USDT = IERC20(0xdAC17F958D2ee523a2206206994597C13D831ec7);
    IERC20 constant USDC = IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
    IERC20 constant SGETH = IERC20(0x72E2F4830b9E45d52F80aC08CB2bEC0FeF72eD9c);

    AggregatorV3Interface internal priceFeed;

    uint256 immutable tvlThreshold;

    constructor() {
        protocolName = "Stargate";
        testedContracts = [STARGATE_USDT_POOL, STARGATE_USDC_POOL, STARGATE_SGETH_POOL];

        // Chainlink ETH/USD price feed on Ethereum Mainnet
        // https://etherscan.io/address/0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419
        priceFeed = AggregatorV3Interface(0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419);

        tvlThreshold = getCurrentBalances() / 10;
    }

    // @notice Get current pool balances
    // @return the sum of tested pool balances (USDT, USDC, ETH)
    function getCurrentBalances() public view returns (uint256) {
        // Grab latest price from Chainlink feed
        (, int256 ethUsdPrice, , , ) = priceFeed.latestRoundData();

        // Exclude negative prices so we can safely cast to uint
        if (ethUsdPrice < 0) {
            ethUsdPrice = 0;
        }

        return (USDT.balanceOf(STARGATE_USDT_POOL) + // 6 decimals
            USDC.balanceOf(STARGATE_USDC_POOL) + // 6 decimals
            (SGETH.balanceOf(STARGATE_SGETH_POOL) * uint256(ethUsdPrice)) /
            10**20);
        // 18 decimals + 8 decimal price
    }

    // @notice Check if current pool balances are greater than TVL threshold
    // @return true if current TVL > 10% of TVL at time of test deploy
    function checkTestPasses() public view override returns (bool) {
        return (getCurrentBalances() > tvlThreshold);
    }
}