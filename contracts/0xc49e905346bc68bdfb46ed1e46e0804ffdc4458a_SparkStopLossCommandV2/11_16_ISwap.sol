// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import { SwapData } from "./../libs/EarnSwapData.sol";

interface ISwap {
    function swapTokens(SwapData calldata swapData) external returns (uint256);
}