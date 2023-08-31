// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

/**
 * @title ICollectionHolderMint
 * @dev This interface represents the functions related to minting a collection of tokens.
 */
interface ICollectionHolderMint {
    // Events
    error AlreadyClaimedFreeMint(); // Fired when a free mint has already been claimed
    error NoTokensProvided(); // Fired when a mint function is called with no tokens provided
    error DuplicatesFound(); // Fired when a mint function is called with duplicate tokens

    /**
     * @dev Returns whether a specific mint has been claimed
     * @param tokenId The ID of the token in question
     * @return A boolean indicating whether the mint has been claimed
     */
    function freeMintClaimed(uint256 tokenId) external view returns (bool);

    /**
     * @dev Returns the address of the collection contract
     * @return The address of the collection contract
     */
    function cre8orsNFTContractAddress() external view returns (address);

    /**
     * @dev Returns the address of the minter utility contract
     * @return The address of the minter utility contract
     */
    function minterUtilityContractAddress() external view returns (address);

    /**
     * @dev Returns the maximum number of free mints claimed by an address
     * @return The maximum number of free mints claimed
     */
    function totalClaimed(address) external view returns (uint256);

    /**
     * @dev Mints a batch of tokens and sends them to a recipient
     * @param tokenIds An array of token IDs to mint
     * @param recipient The address to send the minted tokens to
     * @return The last token ID minted in this batch
     */
    function mint(
        uint256[] calldata tokenIds,
        address recipient
    ) external returns (uint256);

    /**
     * @dev Changes the address of the minter utility contract
     * @param _newMinterUtilityContractAddress The new minter utility contract address
     */
    function setNewMinterUtilityContractAddress(
        address _newMinterUtilityContractAddress
    ) external;

    /**
     * @dev Toggles the claim status of a free mint
     * @param tokenId The ID of the token whose claim status is being toggled
     */
    function toggleHasClaimedFreeMint(uint256 tokenId) external;
}