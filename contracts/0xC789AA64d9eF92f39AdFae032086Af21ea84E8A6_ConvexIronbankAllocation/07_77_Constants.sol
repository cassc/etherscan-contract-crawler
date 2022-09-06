// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.6.11;

import {INameIdentifier} from "contracts/common/Imports.sol";

abstract contract ConvexIronbankConstants is INameIdentifier {
    string public constant override NAME = "convex-ironbank";

    uint256 public constant PID = 29;

    address public constant STABLE_SWAP_ADDRESS =
        0x2dded6Da1BF5DBdF597C45fcFaa3194e53EcfeAF;
    address public constant LP_TOKEN_ADDRESS =
        0x5282a4eF67D9C33135340fB3289cc1711c13638C;
    address public constant REWARD_CONTRACT_ADDRESS =
        0x3E03fFF82F77073cc590b656D42FceB12E4910A8;
}