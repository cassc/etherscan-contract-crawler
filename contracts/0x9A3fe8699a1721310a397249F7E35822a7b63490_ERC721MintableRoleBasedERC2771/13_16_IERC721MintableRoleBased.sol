// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

/**
 * @dev Extension of {ERC721} that allows a specific role to mint tokens.
 */
interface IERC721MintableRoleBased {
    /**
     * @dev Mints `amount` new tokens for `to`.
     */
    function mintByRole(address to, uint256 amount) external;

    /**
     * @dev Mints multiple `amount`s of new tokens for every single address in `tos`.
     */
    function mintByRole(address[] calldata tos, uint256[] calldata amounts) external;

    /**
     * @dev Mint constant amount of new tokens for multiple addresses (e.g. 1 nft for each address).
     */
    function mintByRole(address[] calldata tos, uint256 amount) external;

    /**
     * @dev Mint new tokens for single address with dedicated tokenURIs.
     */
    function mintByRole(
        address to,
        uint256 amount,
        string[] calldata tokenURIs
    ) external;

    /**
     * @dev Mint new tokens for multiple addresses with dedicated tokenURIs.
     */
    function mintByRole(address[] calldata tos, string[] calldata tokenURIs) external;
}