// SPDX-License-Identifier: MIT

// @author: Fair.xyz dev

pragma solidity 0.8.19;

interface IFairxyz1155Editions {
    /**
     * @notice Burn Tokens
     * @dev Burns an amount of a single edition/token, reducing the balance of `from`.
     *
     * @param from the address of the owner to burn tokens for
     * @param editionId the ID of the edition to burn
     * @param amount the number of tokens to burn
     */
    function burn(address from, uint256 editionId, uint256 amount) external;
}