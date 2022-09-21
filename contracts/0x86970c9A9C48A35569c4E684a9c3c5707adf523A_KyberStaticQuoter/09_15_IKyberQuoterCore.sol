// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity =0.7.6;

import { IUniV3likeQuoterCore } from '../../IUniV3likeQuoterCore.sol';

// temporary swap variables, some of which will be used to update the pool state
struct SwapData {
    int256 specifiedAmount; // the specified amount (could be tokenIn or tokenOut)
    int256 returnedAmount; // the opposite amout of sourceQty
    uint160 sqrtP; // current sqrt(price), multiplied by 2^96
    int24 currentTick; // the tick associated with the current price
    int24 nextTick; // the next initialized tick
    uint160 nextSqrtP; // the price of nextTick
    bool isToken0; // true if specifiedAmount is in token0, false if in token1
    bool isExactInput; // true = input qty, false = output qty
    uint128 baseL; // the cached base pool liquidity without reinvestment liquidity
    uint128 reinvestL; // the cached reinvestment liquidity
}

interface IKyberQuoterCore is IUniV3likeQuoterCore {}