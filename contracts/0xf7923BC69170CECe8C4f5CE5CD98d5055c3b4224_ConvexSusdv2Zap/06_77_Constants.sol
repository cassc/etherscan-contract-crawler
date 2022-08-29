// SPDX-License-Identifier: BUSDL-1.1
pragma solidity 0.6.11;

import {INameIdentifier} from "contracts/common/Imports.sol";

abstract contract ConvexSusdv2Constants is INameIdentifier {
    string public constant override NAME = "convex-susdv2";

    uint256 public constant PID = 4;

    address public constant STABLE_SWAP_ADDRESS =
        0xA5407eAE9Ba41422680e2e00537571bcC53efBfD;
    address public constant LP_TOKEN_ADDRESS =
        0xC25a3A3b969415c80451098fa907EC722572917F;
    address public constant REWARD_CONTRACT_ADDRESS =
        0x22eE18aca7F3Ee920D01F25dA85840D12d98E8Ca;

    address public constant SUSD_ADDRESS =
        0x57Ab1ec28D129707052df4dF418D58a2D46d5f51;
    address public constant SNX_ADDRESS =
        0xC011a73ee8576Fb46F5E1c5751cA3B9Fe0af2a6F;
}