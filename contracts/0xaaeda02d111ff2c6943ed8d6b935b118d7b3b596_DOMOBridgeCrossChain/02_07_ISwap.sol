// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.19;

interface ISwap {
    /**
     * Creates `amount` tokens and assigns them to `recipient`, increasing
     * the total supply.
     *
     * Requirements
     *
     * - `msg.sender` must be the token owner
     * - `_mintable` must be true
     */
    function mint(address recipient, uint256 amount) external;

    /**
    * Burn `amount` tokens and decreasing the total supply.
    */
    function burn(uint256 amount) external;
}