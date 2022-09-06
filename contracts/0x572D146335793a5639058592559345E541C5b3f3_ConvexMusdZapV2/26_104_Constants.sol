// SPDX-License-Identifier: BUSDL-1.1
pragma solidity 0.6.11;

import {
    IStableSwap
} from "contracts/protocols/curve/common/interfaces/Imports.sol";
import {IDepositor} from "./IDepositor.sol";

abstract contract DepositorConstants {
    IStableSwap public constant BASE_POOL =
        IStableSwap(0xbEbc44782C7dB0a1A60Cb6fe97d0b483032FF1C7);

    // A depositor "zap" contract for metapools
    IDepositor public constant DEPOSITOR =
        IDepositor(0xA79828DF1850E8a3A3064576f380D90aECDD3359);
}