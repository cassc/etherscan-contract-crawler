// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.4;

import "./ISwapPair.sol";

interface ILiquidityLockedERC20 {
    function setLiquidityLock(ISwapPair _liquidityPair, bool _locked) external;
}