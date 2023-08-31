// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.13;

interface IButtonswapERC20Events {
    /**
     * @notice Emitted when the allowance of a `spender` for an `owner` is set by a call to {IButtonswapERC20-approve}.
     * `value` is the new allowance.
     * @param owner The account that has granted approval
     * @param spender The account that has been given approval
     * @param value The amount the spender can transfer
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @notice Emitted when `value` tokens are moved from one account (`from`) to another (`to`).
     * @param from The account that sent the tokens
     * @param to The account that received the tokens
     * @param value The amount of tokens transferred
     */
    event Transfer(address indexed from, address indexed to, uint256 value);
}