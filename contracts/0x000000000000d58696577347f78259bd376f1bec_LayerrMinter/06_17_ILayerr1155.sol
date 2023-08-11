// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title ILayerr1155
 * @author 0xth0mas (Layerr)
 * @notice ILayerr1155 interface defines functions required in an ERC1155 token contract to callable by the LayerrMinter contract.
 */
interface ILayerr1155 {

    /**
     * @notice Mints tokens to the recipients, each recipient gets the corresponding tokenId in the `tokenIds` array
     * @dev This function should be protected by a role so that it is not callable by any address
     * @dev `recipients`, `tokenIds` and `amounts` arrays must be equal length, each recipient will receive the corresponding 
     *      tokenId and amount from the `tokenIds` and `amounts` arrays
     * @param recipients addresses to airdrop tokens to
     * @param tokenIds ids of tokens to be airdropped to recipients
     * @param amounts amounts of tokens to be airdropped to recipients
     */
    function airdrop(address[] calldata recipients, uint256[] calldata tokenIds, uint256[] calldata amounts) external;

    /**
     * @notice Mints `amount` of `tokenId` to `to`.
     * @dev `minter` and `to` may be the same address but are passed as two separate parameters to properly account for
     *      allowlist mints where a minter is using a delegated wallet to mint
     * @param minter address that the mint count will be credited to
     * @param to address that will receive the tokens
     * @param tokenId id of the token to mint
     * @param amount amount of token to mint
     */
    function mintTokenId(address minter, address to, uint256 tokenId, uint256 amount) external;

    /**
     * @notice Mints `amount` of `tokenId` to `to`.
     * @dev `minter` and `to` may be the same address but are passed as two separate parameters to properly account for
     *      allowlist mints where a minter is using a delegated wallet to mint
     * @param minter address that the mint count will be credited to
     * @param to address that will receive the tokens
     * @param tokenIds array of ids to mint
     * @param amounts array of amounts to mint
     */
    function mintBatchTokenIds(
        address minter,
        address to,
        uint256[] calldata tokenIds,
        uint256[] calldata amounts
    ) external;

    /**
     * @notice Burns `tokenId` from `from` address
     * @dev This function should check that the caller has permission to burn tokens on behalf of `from`
     * @param from address to burn the tokenId from
     * @param tokenId id of token to be burned
     * @param amount amount of `tokenId` to burn from `from`
     */
    function burnTokenId(
        address from,
        uint256 tokenId,
        uint256 amount
    ) external;

    /**
     * @notice Burns `tokenId` from `from` address
     * @dev This function should check that the caller has permission to burn tokens on behalf of `from`
     * @param from address to burn the tokenId from
     * @param tokenIds array of token ids to be burned
     * @param amounts array of amounts to burn from `from`
     */
    function burnBatchTokenIds(
        address from,
        uint256[] calldata tokenIds,
        uint256[] calldata amounts
    ) external;

    /**
     * @notice Emits URI event for tokens provided
     * @param tokenIds array of token ids to emit MetadataUpdate event for
     */
    function updateMetadataSpecificTokens(uint256[] calldata tokenIds) external;

    /**
     * @notice Returns the total supply of ERC1155 tokens in circulation for given `id`.
     * @param id the token id to check total supply of
     */
    function totalSupply(uint256 id) external view returns (uint256);

    /**
     * @notice Returns the total number of tokens minted for the contract and the number of tokens minted by the `minter`
     * @param minter address to check for number of tokens minted
     * @param id the token id to check number of tokens minted for
     * @return totalMinted total number of ERC1155 tokens for given `id` minted since token launch
     * @return minterMinted total number of ERC1155 tokens for given `id` minted by the `minter`
     */
    function totalMintedCollectionAndMinter(address minter, uint256 id) external view returns(uint256 totalMinted, uint256 minterMinted);
}