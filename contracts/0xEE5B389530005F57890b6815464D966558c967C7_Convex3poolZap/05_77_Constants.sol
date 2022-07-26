// SPDX-License-Identifier: BUSDL-1.1
pragma solidity 0.6.11;

import {INameIdentifier} from "contracts/common/Imports.sol";

abstract contract Convex3poolConstants is INameIdentifier {
    string public constant override NAME = "convex-3pool";

    uint256 public constant PID = 9;

    address public constant STABLE_SWAP_ADDRESS =
        0xbEbc44782C7dB0a1A60Cb6fe97d0b483032FF1C7;
    address public constant LP_TOKEN_ADDRESS =
        0x6c3F90f043a72FA612cbac8115EE7e52BDe6E490;
    address public constant REWARD_CONTRACT_ADDRESS =
        0x689440f2Ff927E1f24c72F1087E1FAF471eCe1c8;
}