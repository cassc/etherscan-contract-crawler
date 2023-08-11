// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title ILayerr721
 * @author 0xth0mas (Layerr)
 * @notice ILayerr721 interface defines functions required in an ERC721 token contract to callable by the LayerrMinter contract.
 * @dev ILayerr721 should be used for non-sequential token minting.
 */
interface ILayerr721 {
    /// @dev Thrown when two or more sets of arrays are supplied that require equal lengths but differ in length.
    error ArrayLengthMismatch();

    /**
     * @notice Mints tokens to the recipients, each recipient gets the corresponding tokenId in the `tokenIds` array
     * @dev This function should be protected by a role so that it is not callable by any address
     * @param recipients addresses to airdrop tokens to
     * @param tokenIds ids of tokens to be airdropped to recipients
     */
    function airdrop(address[] calldata recipients, uint256[] calldata tokenIds) external;

    /**
     * @notice Mints `tokenId` to `to`.
     * @dev `minter` and `to` may be the same address but are passed as two separate parameters to properly account for
     *      allowlist mints where a minter is using a delegated wallet to mint
     * @param minter address that the mint count will be credited to
     * @param to address that will receive the token
     * @param tokenId the id of the token to mint
     */
    function mintTokenId(address minter, address to, uint256 tokenId) external;

    /**
     * @notice Mints `tokenIds` to `to`.
     * @dev `minter` and `to` may be the same address but are passed as two separate parameters to properly account for
     *      allowlist mints where a minter is using a delegated wallet to mint
     * @param minter address that the mint count will be credited to
     * @param to address that will receive the tokens
     * @param tokenIds the ids of tokens to mint
     */
    function mintBatchTokenIds(
        address minter,
        address to,
        uint256[] calldata tokenIds
    ) external;

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