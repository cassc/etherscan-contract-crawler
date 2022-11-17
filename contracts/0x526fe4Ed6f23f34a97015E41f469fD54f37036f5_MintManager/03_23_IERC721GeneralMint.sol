// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

/**
 * @dev General721 mint interface
 * @author [email protected]
 */
interface IERC721GeneralMint {
    /**
     * @dev Mint one token to one recipient
     * @param recipient Recipient of minted NFT
     */
    function mintOneToOneRecipient(address recipient) external;

    /**
     * @dev Mint an amount of tokens to one recipient
     * @param recipient Recipient of minted NFTs
     * @param amount Amount of NFTs minted
     */
    function mintAmountToOneRecipient(address recipient, uint256 amount) external;

    /**
     * @dev Mint one token to multiple recipients. Useful for use-cases like airdrops
     * @param recipients Recipients of minted NFTs
     */
    function mintOneToMultipleRecipients(address[] calldata recipients) external;

    /**
     * @dev Mint the same amount of tokens to multiple recipients
     * @param recipients Recipients of minted NFTs
     * @param amount Amount of NFTs minted to each recipient
     */
    function mintSameAmountToMultipleRecipients(address[] calldata recipients, uint256 amount) external;
}