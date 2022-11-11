// SPDX-License-Identifier: U-U-U-UPPPPP!!!
pragma solidity ^0.7.4;

import "./IPancakePair.sol";

interface ILiquidityLockedERC20
{
    function setLiquidityLock(IPancakePair _liquidityPair, bool _locked) external;
}