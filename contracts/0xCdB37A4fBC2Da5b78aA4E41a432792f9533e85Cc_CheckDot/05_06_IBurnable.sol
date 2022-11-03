// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

/**
 * @title IBurnable
 * @author Jeremy Guyet (@jguyet)
 * @dev The IBurnable interface is a function dedicated to
 * the ERC20 to burn tokens.
 */
interface IBurnable {
    /**
     * @dev Destroys `amount` tokens from `msg.sender`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `msg.sender` cannot be the zero address.
     * - `msg.sender` must have at least `amount` tokens.
     */
    function burn(uint256 amount) external returns (bool);
}