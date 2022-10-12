// SPDX-License-Identifier: GPL-3.0

/// @title buyETH Callback interface

/*********************************
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░█████████░░█████████░░░ *
 * ░░░░░░██░░░████░░██░░░████░░░ *
 * ░░██████░░░████████░░░████░░░ *
 * ░░██░░██░░░████░░██░░░████░░░ *
 * ░░██░░██░░░████░░██░░░████░░░ *
 * ░░░░░░█████████░░█████████░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 *********************************/

pragma solidity ^0.8.15;

interface IBuyETHCallback {
    /**
     * @notice Called on the {to} in TokenBuyer#buyETH, with `msg.value` ETH payment in exchange for {amount} TokenBuyer#paymentToken.
     * @param caller the `msg.sender` in TokenBuyer#buyETH
     * @param amount the TokenBuyer#paymentToken amount caller is buying ETH with
     * @param data arbitrary data passed through by the caller via the TokenBuyer#buyETH call
     */
    function buyETHCallback(
        address caller,
        uint256 amount,
        bytes calldata data
    ) external payable;
}