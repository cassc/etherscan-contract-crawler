//SPDX-License-Identifier: MIT

/***
 *      ______             _______   __
 *     /      \           |       \ |  \
 *    |  $$$$$$\ __    __ | $$$$$$$\| $$  ______    _______  ______ ____    ______
 *    | $$$\| $$|  \  /  \| $$__/ $$| $$ |      \  /       \|      \    \  |      \
 *    | $$$$\ $$ \$$\/  $$| $$    $$| $$  \$$$$$$\|  $$$$$$$| $$$$$$\$$$$\  \$$$$$$\
 *    | $$\$$\$$  >$$  $$ | $$$$$$$ | $$ /      $$ \$$    \ | $$ | $$ | $$ /      $$
 *    | $$_\$$$$ /  $$$$\ | $$      | $$|  $$$$$$$ _\$$$$$$\| $$ | $$ | $$|  $$$$$$$
 *     \$$  \$$$|  $$ \$$\| $$      | $$ \$$    $$|       $$| $$ | $$ | $$ \$$    $$
 *      \$$$$$$  \$$   \$$ \$$       \$$  \$$$$$$$ \$$$$$$$  \$$  \$$  \$$  \$$$$$$$
 *
 *
 *
 */

pragma solidity ^0.8.4;

/**
 * @dev Contract module that helps prevent swap callback direct calls.
 *
 * Inheriting from `SwapGuard` will make the {swapCall} and {swapCallBack} modifiers
 * available, which can be applied to functions to make sure there are no direct swap function call.
 *
 */

import {
    IUniswapV3SwapCallback
} from "@uniswap/v3-core/contracts/interfaces/callback/IUniswapV3SwapCallback.sol";

abstract contract SwapGuard is IUniswapV3SwapCallback {
    address private constant _NOT_IN_SWAP =
        0x000000000000000000000000000000000000dEaD;
    address internal _swapPool;

    constructor() {
        _swapPool = _NOT_IN_SWAP;
    }

    modifier doSwap(address pool) {
        require(_swapPool == _NOT_IN_SWAP, "SwapGuard: reentrant call");
        _swapPool = pool;
        _;
        _swapPool = _NOT_IN_SWAP;
    }

    modifier guardSwap() {
        require(
            _swapPool == msg.sender,
            "SwapGuard: direct swap callback call"
        );
        _;
    }
}