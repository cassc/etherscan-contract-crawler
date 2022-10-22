// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

/**
 * @dev Extension of {ERC20} that allows a specific role to mint tokens.
 */
interface IERC20MintableRoleBased {
    /**
     * @dev Creates `amount` new tokens for `to`, of token type `id`.
     *
     * See {ERC20-_mint}.
     *
     * Requirements:
     *
     * - the caller must have MINTER_ROLE.
     */
    function mintByRole(address to, uint256 amount) external;

    function mintByRole(address[] calldata tos, uint256[] calldata amounts) external;
}