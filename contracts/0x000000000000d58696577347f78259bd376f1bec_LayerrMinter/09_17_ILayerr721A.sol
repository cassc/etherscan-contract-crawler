// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title ILayerr721A
 * @author 0xth0mas (Layerr)
 * @notice ILayerr721A interface defines functions required in an ERC721A token contract to callable by the LayerrMinter contract.
 * @dev ILayerr721A should be used for sequential token minting.
 */
interface ILayerr721A {
    /// @dev Thrown when two or more sets of arrays are supplied that require equal lengths but differ in length.
    error ArrayLengthMismatch();


    /**
     * @notice Mints tokens to the recipients, each recipient receives the corresponding amount of tokens in the `amounts` array
     * @dev This function should be protected by a role so that it is not callable by any address
     * @param recipients addresses to airdrop tokens to
     * @param amounts amount of tokens that should be airdropped to each recipient
     */
    function airdrop(address[] calldata recipients, uint256[] calldata amounts) external;


    /**
     * @notice Sequentially mints `quantity` of tokens to `to`
     * @dev `minter` and `to` may be the same address but are passed as two separate parameters to properly account for
     *      allowlist mints where a minter is using a delegated wallet to mint
     * @param minter address that the mint count will be credited to
     * @param to address that will receive the tokens
     * @param quantity the number of tokens to sequentially mint to `to`
     */
    function mintSequential(address minter, address to, uint256 quantity) external;

    /**
     * @notice Burns `tokenId` from `from` address
     * @dev This function should check that the caller has permission to burn tokens on behalf of `from`
     * @param from address to burn the tokenId from
     * @param tokenId id of token to be burned
     */
    function burnTokenId(address from, uint256 tokenId) external;

    /**
     * @notice Burns `tokenIds` from `from` address
     * @dev This function should check that the caller has permission to burn tokens on behalf of `from`
     * @param from address to burn the tokenIds from
     * @param tokenIds ids of tokens to be burned
     */
    function burnBatchTokenIds(
        address from,
        uint256[] calldata tokenIds
    ) external;

    /**
     * @notice Emits ERC-4906 BatchMetadataUpdate event for all tokens
     */
    function updateMetadataAllTokens() external;

    /**
     * @notice Emits ERC-4906 MetadataUpdate event for tokens provided
     * @param tokenIds array of token ids to emit MetadataUpdate event for
     */
    function updateMetadataSpecificTokens(uint256[] calldata tokenIds) external;

    /**
     * @notice Returns the total supply of ERC721 tokens in circulation.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @notice Returns the total number of tokens minted for the contract and the number of tokens minted by the `minter`
     * @param minter address to check for number of tokens minted
     * @return totalMinted total number of ERC721 tokens minted since token launch
     * @return minterMinted total number of ERC721 tokens minted by the `minter`
     */
    function totalMintedCollectionAndMinter(address minter) external view returns(uint256 totalMinted, uint256 minterMinted);
}