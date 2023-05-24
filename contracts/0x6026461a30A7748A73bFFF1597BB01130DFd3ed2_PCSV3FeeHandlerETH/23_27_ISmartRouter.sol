// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import './IV2SwapRouter.sol';
import './IV3SwapRouter.sol';
import './IStableSwapRouter.sol';
import './IMulticallExtended.sol';

/// @title Router token swapping functionality
interface ISmartRouter is IV2SwapRouter, IV3SwapRouter, IStableSwapRouter, IMulticallExtended {
    function WETH9() external view returns (address);
}