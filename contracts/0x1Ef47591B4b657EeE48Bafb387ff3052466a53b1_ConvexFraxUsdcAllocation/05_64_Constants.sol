// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.6.11;

import {INameIdentifier} from "contracts/common/Imports.sol";

abstract contract ConvexFraxUsdcConstants is INameIdentifier {
    string public constant override NAME = "convex-fraxusdc";

    uint256 public constant PID = 100;

    address public constant STABLE_SWAP_ADDRESS =
        0xDcEF968d416a41Cdac0ED8702fAC8128A64241A2;
    address public constant LP_TOKEN_ADDRESS =
        0x3175Df0976dFA876431C2E9eE6Bc45b65d3473CC;
    address public constant REWARD_CONTRACT_ADDRESS =
        0x7e880867363A7e321f5d260Cade2B0Bb2F717B02;

    address public constant FRAX_ADDRESS =
        0x853d955aCEf822Db058eb8505911ED77F175b99e;
    /**
     * @dev USDC gets imported by `Curve3poolUnderlyerConstants`
     * in zap and allocation contracts
     */
    //address public constant USDC_ADDRESS =
    //0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
}