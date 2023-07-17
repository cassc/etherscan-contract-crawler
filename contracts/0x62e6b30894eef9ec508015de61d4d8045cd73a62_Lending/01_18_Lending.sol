// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {AaveV2} from "./AaveV2.sol";
import {CompoundV2} from "./CompoundV2.sol";
import {CompoundV3USDC} from "./CompoundV3USDC.sol";
import {Euler} from "./Euler.sol";
import {DefiOp} from "../DefiOp.sol";

contract Lending is AaveV2, CompoundV2, CompoundV3USDC, Euler {
    function _postInit()
        internal
        override(CompoundV2, CompoundV3USDC, Euler, DefiOp)
    {
        CompoundV2._postInit();
        CompoundV3USDC._postInit();
        Euler._postInit();
    }
}