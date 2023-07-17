// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

/**
 * @dev Mint interface on editions contracts
 * @author [email protected]
 */
interface IERC721EditionMint {
    /**
     * @dev Mints one NFT to one recipient
     * @param editionId Edition to mint the NFT on
     * @param recipient Recipient of minted NFT
     */
    function mintOneToRecipient(uint256 editionId, address recipient) external returns (uint256);

    /**
     * @dev Mints an amount of NFTs to one recipient
     * @param editionId Edition to mint the NFTs on
     * @param recipient Recipient of minted NFTs
     * @param amount Amount of NFTs minted
     */
    function mintAmountToRecipient(
        uint256 editionId,
        address recipient,
        uint256 amount
    ) external returns (uint256);

    /**
     * @dev Mints one NFT each to a number of recipients
     * @param editionId Edition to mint the NFTs on
     * @param recipients Recipients of minted NFTs
     */
    function mintOneToRecipients(uint256 editionId, address[] memory recipients) external returns (uint256);

    /**
     * @dev Mints an amount of NFTs each to a number of recipients
     * @param editionId Edition to mint the NFTs on
     * @param recipients Recipients of minted NFTs
     * @param amount Amount of NFTs minted per recipient
     */
    function mintAmountToRecipients(
        uint256 editionId,
        address[] memory recipients,
        uint256 amount
    ) external returns (uint256);
}