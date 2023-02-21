// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

/**
 * @title Rescuable contract interface
 * @author CloudWalk Inc.
 * @dev Allows to rescue ERC20 tokens locked up in the contract.
 */
interface IRescuable {
    // -------------------- Functions -----------------------------------

    /**
     * @dev Withdraws ERC20 tokens locked up in the contract.
     * @param token The address of the ERC20 token contract.
     * @param to The address of the recipient of tokens.
     * @param amount The amount of tokens to withdraw.
     */
    function rescueERC20(address token, address to, uint256 amount) external;
}