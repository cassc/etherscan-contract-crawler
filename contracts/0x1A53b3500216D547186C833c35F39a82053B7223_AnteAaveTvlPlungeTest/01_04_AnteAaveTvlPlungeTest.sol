// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../AnteTest.sol";
import "../interfaces/IERC20.sol";

// @title AAVE ethereum markets do not lose 85% of their assets
// @notice Ensure that AAVE Ethereum markets don't drop under 15% for top 5 tokens
contract AnteAaveTvlPlungeTest is AnteTest("Ensure that AAVE Ethereum markets don't drop under 15% for top 5 tokens") {
    IERC20[5] public tokens = [
        IERC20(0x030bA81f1c18d280636F32af80b9AAd02Cf0854e), // aWETH
        IERC20(0xBcca60bB61934080951369a648Fb03DF4F96263C), // aUSDC
        IERC20(0x1982b2F5814301d4e9a8b0201555376e62F82428), // aSTETH
        IERC20(0x9ff58f4fFB29fA2266Ab25e75e2A8b3503311656), // aWBTC
        IERC20(0x3Ed3B47Dd13EC9a98b44e6204A523E766B225811) // aUSDT
    ];

    uint256 private constant PERCENT_DROP_THRESHOLD = 15;

    // threshold amounts under which the test fails
    uint256[5] public thresholds;

    constructor() {
        protocolName = "AAVE";

        for (uint256 i = 0; i < 5; i++) {
            testedContracts.push(address(tokens[i]));
            thresholds[i] = (tokens[i].totalSupply() * PERCENT_DROP_THRESHOLD) / 100;
        }
    }

    function checkTestPasses() external view override returns (bool) {
        for (uint256 i = 0; i < 5; i++) {
            if (tokens[i].totalSupply() < thresholds[i]) {
                return false;
            }
        }

        return true;
    }
}