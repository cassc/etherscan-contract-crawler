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
    uint256 private constant _NOT_IN_SWAP = 1;
    uint256 private constant _IN_SWAP = 2;

    uint256 private _swapStatus;

    constructor() {
        _swapStatus = _NOT_IN_SWAP;
    }

    modifier swapCall() {
        require(_swapStatus != _IN_SWAP, "SwapGuard: reentrant call");
        _swapStatus = _IN_SWAP;
        _;
        _swapStatus = _NOT_IN_SWAP;
    }

    modifier swapCallBack() {
        require(
            _swapStatus == _IN_SWAP,
            "SwapGuard: direct swap callback call"
        );
        _;
    }
}