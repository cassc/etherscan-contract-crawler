// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

/**
 * @dev Interface used to mint multiple NFT in our case multiple Land
 *
 * - Contract must be MINTER_ROLE on the NFT contract
 *
 */
interface IMinter {
    /**
     * @dev TokenAndAddress is a struct use to call {mintIdsTo}
     *
     * - `uint256 tokenId`: tokenId to mint of an ERC721
     * - `address to`: receiver of the token
     *
     */
    struct TokenAndAddress {
        uint256 tokenId;
        address to;
    }

    /**
     * @dev AmountAndAddress is a struct use to call {mintAutoIdsTo}
     *
     * - `uint256 amount`: number of token to mint of an ERC721
     * - `address to`: receiver of the token
     *
     */
    struct AmountAndAddress {
        uint256 amount;
        address to;
    }

    /**
     * @dev Mint given tokenIds to on address
     *
     * Requirements:
     *
     * - Caller must be `MINTER_ROLE` on Minter contract
     * - Contract must be `MINTER_ROLE` on NFT contract
     */
    function mintIds(
        address nftContract,
        address to,
        uint256[] memory tokenIds
    ) external;

    /**
     * @dev Mint given tokenIds to multiple addresses
     *
     * Requirements:
     *
     * - Caller must be `MINTER_ROLE` on Minter contract
     * - Contract must be `MINTER_ROLE` on NFT contract
     */
    function mintIdsTo(address nftContract, TokenAndAddress[] memory tokenIdsTo) external;

    /**
     * @dev Mint tokens with autoId to one address with given amount
     *
     * Requirements:
     *
     * - Caller must be `MINTER_ROLE` on Minter contract
     * - Contract must be `MINTER_ROLE` on NFT contract
     */
    function mintAutoIds(
        address nftContract,
        address to,
        uint256 amount
    ) external;

    /**
     * @dev Mint tokens with autoId to multiple addresses with given amount
     *
     * Requirements:
     *
     * - Caller must be `MINTER_ROLE` on Minter contract
     * - Contract must be `MINTER_ROLE` on NFT contract
     */
    function mintAutoIdsTo(address nftContract, AmountAndAddress[] memory amountToAddresses)
        external;
}