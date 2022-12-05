// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {AnteTest} from "../AnteTest.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title Optimism Bridge on Ethereum doesn't lose significant asset balance
/// @notice Ante Test to check if main Optimism Bridge contract on Eth mainnet
///         loses 90% of its top asset holdings (as of test deployment)
contract AnteOptimismBridgeAssetBalanceTest is AnteTest(
    "Optimism Bridge doesn't lose 90% of any of its top assets on Eth Mainnet"
) {
    // As of 2022-12-04, the top assets on the L1 side of the bridge are ETH,
    // USDC, USDT, and WBTC, representing 92.5% of value stored on the L1 side
    // https://etherscan.io/address/0x99C9fc46f92E8a1c0deC1b1747d010903E884bE1
    address public constant OPTIMISM_MAIN_BRIDGE = 0x99C9fc46f92E8a1c0deC1b1747d010903E884bE1;
    // https://etherscan.io/address/0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48
    IERC20 public constant USDC = IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
    // https://etherscan.io/address/0xdAC17F958D2ee523a2206206994597C13D831ec7
    IERC20 public constant USDT = IERC20(0xdAC17F958D2ee523a2206206994597C13D831ec7);
    // https://etherscan.io/address/0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599
    IERC20 public constant WBTC = IERC20(0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599);

    uint256 public immutable ethBalanceAtDeploy;
    uint256 public immutable usdcBalanceAtDeploy;
    uint256 public immutable usdtBalanceAtDeploy;
    uint256 public immutable wbtcBalanceAtDeploy;

    constructor() {
        protocolName = "Optimism Bridge";
        testedContracts = [OPTIMISM_MAIN_BRIDGE];

        ethBalanceAtDeploy = OPTIMISM_MAIN_BRIDGE.balance;
        usdcBalanceAtDeploy = USDC.balanceOf(OPTIMISM_MAIN_BRIDGE);
        usdtBalanceAtDeploy = USDT.balanceOf(OPTIMISM_MAIN_BRIDGE);
        wbtcBalanceAtDeploy = WBTC.balanceOf(OPTIMISM_MAIN_BRIDGE);
    }

    /// @notice checks balance of top 4 assets on Optimism Bridge doesn't drop
    /// @return true if bridge has more than 10% of the original asset balance
    ///         at time of test deploy across all checked assets
    function checkTestPasses() external view override returns (bool) {
        return
            OPTIMISM_MAIN_BRIDGE.balance * 10 > ethBalanceAtDeploy &&
            USDC.balanceOf(OPTIMISM_MAIN_BRIDGE) * 10 > usdcBalanceAtDeploy &&
            USDT.balanceOf(OPTIMISM_MAIN_BRIDGE) * 10 > usdtBalanceAtDeploy &&
            WBTC.balanceOf(OPTIMISM_MAIN_BRIDGE) * 10 > wbtcBalanceAtDeploy;
    }
}