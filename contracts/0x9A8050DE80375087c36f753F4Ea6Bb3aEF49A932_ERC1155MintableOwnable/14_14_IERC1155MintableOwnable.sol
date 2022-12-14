// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

/**
 * @dev Extension of {ERC1155} that allows diamond owner to mint tokens.
 */
interface IERC1155MintableOwnable {
    /**
     * @dev Creates `amount` new tokens for `to`, of token type `id`.
     *
     * See {ERC1155-_mint}.
     *
     * Requirements:
     *
     * - the caller must be diamond owner.
     */
    function mintByOwner(
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    function mintByOwner(
        address[] calldata tos,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes[] calldata datas
    ) external;
}