// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

/**
 * @notice General721 mint interface
 * @author [email protected]
 */
interface IERC721GeneralMint {
    /**
     * @notice Mint one token to one recipient
     * @param recipient Recipient of minted NFT
     */
    function mintOneToOneRecipient(address recipient) external returns (uint256);

    /**
     * @notice Mint an amount of tokens to one recipient
     * @param recipient Recipient of minted NFTs
     * @param amount Amount of NFTs minted
     */
    function mintAmountToOneRecipient(address recipient, uint256 amount) external;

    /**
     * @notice Mint one token to multiple recipients. Useful for use-cases like airdrops
     * @param recipients Recipients of minted NFTs
     */
    function mintOneToMultipleRecipients(address[] calldata recipients) external;

    /**
     * @notice Mint the same amount of tokens to multiple recipients
     * @param recipients Recipients of minted NFTs
     * @param amount Amount of NFTs minted to each recipient
     */
    function mintSameAmountToMultipleRecipients(address[] calldata recipients, uint256 amount) external;

    /**
     * @notice Mint a chosen token id to a single recipient
     * @param recipient Recipient of chosen NFT
     * @param tokenId ID of NFT to mint
     */
    function mintSpecificTokenToOneRecipient(address recipient, uint256 tokenId) external;

    /**
     * @notice Mint chosen token ids to a single recipient
     * @param recipient Recipient of chosen NFT
     * @param tokenIds IDs of NFTs to mint
     */
    function mintSpecificTokensToOneRecipient(address recipient, uint256[] calldata tokenIds) external;
}