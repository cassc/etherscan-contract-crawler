// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.4;

interface ICedarSFTLazyMintV0 {
    /// @dev Emitted when tokens are lazy minted.
    event TokensLazyMinted(uint256 startTokenId, uint256 endTokenId, string baseURI);
    
    /**
     *  @notice Lets an account with `MINTER_ROLE` lazy mint 'n' NFTs.
     *          The URIs for each token is the provided `_baseURIForTokens` + `{tokenId}`.
     *
     *  @param amount           The amount of NFTs to lazy mint.
     *  @param baseURIForTokens The URI for the NFTs to lazy mint.
     */
    function lazyMint(uint256 amount, string calldata baseURIForTokens) external;
}