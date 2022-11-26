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
     * @dev Mint a new token with a dedicated tokenURI.
     */
    function mintByRole(
        address to,
        uint256 amount,
        string[] calldata tokenURIs
    ) external;
}