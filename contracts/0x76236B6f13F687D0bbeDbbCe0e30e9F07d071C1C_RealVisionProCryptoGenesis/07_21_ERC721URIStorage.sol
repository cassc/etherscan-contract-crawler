// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

/**
 * @dev ERC721 token with storage based token URI management.
 *
 * This contract is almost entirely based on the OpenZeppelin implementation, but
 * it modifies the tokenURI() function because we don't think the contract should dictate
 * whether the metadata MUST all live in the same folder structure off-chain. The
 * developer should be able to decide if one token lives in one folder, and another
 * token is in an different folder. However, because OpenZeppelin's implementation
 * concatenates each token's URI with the baseURI (if it exists), their implementation
 * is not able to meet the following criteria:
 *   - have a base URI where any non-customized NFTs will have their metadata
 *   - allow any customized NFTs to have their metadata at an arbitrary
 *     location (this could be a separate folder or separate infrastructure entirely
 *     from the rest of the collection. Maybe not, but the choice should be available
 *     to the developer; the contract should be agnostic and not enforce the same
 *     location for all.)
 * For example, the openzeppelin implementation would make it very difficult to
 * change the metadata about one NFT in the collection if all NFT's metadata were initially
 * uploaded as a folder to IPFS.
 */
abstract contract ERC721URIStorage is ERC721 {
    using Strings for uint256;

    // Optional mapping for token URIs
    mapping(uint256 => string) private _customTokenURIs;

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory _URIToReturn) {
        require(_exists(tokenId), "ERC721URIStorage: URI query for nonexistent token");

        string memory _tokenURI = _customTokenURIs[tokenId];

        // NOTE !!!
        // The behavior below is modified from the OpenZeppelin implementation.
        // OpenZeppelin concatenates customURIs for tokens to the baseURI
        // We do not concatenate those two things; if a custom URI is set for a token,
        // it should be a fully independent URI (not something that is dependent on some sort of 'base' string).
        // Concatenation with the tokenId is only performed for tokens using the baseURI. For tokens that
        // have had a unique URI set, no concatenation is performed, because this allows for unique URIs in
        // IPFS to work, for example (where concatenating a tokenId would change/break the CID.)
        
        // If a custom URI has been set for the token, use it
        if (bytes(_tokenURI).length > 0) {
            _URIToReturn = _tokenURI;
        }  // otherwise, use the default/global baseURI
        else {
            _URIToReturn = string(abi.encodePacked(_baseURI(), tokenId.toString()));
        }
    }

    /**
     * @dev Sets `_tokenURI` as the tokenURI of `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _setCustomTokenURI(uint256 tokenId, string calldata _tokenURI) internal virtual {
        require(_exists(tokenId), "ERC721URIStorage: URI set of nonexistent token");
        _customTokenURIs[tokenId] = _tokenURI;
    }

    /**
     * @dev Deletes custom base tokenURI, if one had previously been set for a specific token.
     *
     * Requirements:
     *
     * - a custom URI must have previously been set for the token.
     */
    function _deleteCustomTokenURI(uint256 tokenId) internal virtual {
        require(
            bytes(_customTokenURIs[tokenId]).length != 0,
            "ERC721URIStorage: Token does not have a custom URI mapping.");
        delete _customTokenURIs[tokenId];
    }

    /**
     * @dev Removes token-specific URI information if it exists, when a token is burned.
     */
    function _burn(uint256 tokenId) internal virtual override {
        super._burn(tokenId);

        if (bytes(_customTokenURIs[tokenId]).length != 0) {
            delete _customTokenURIs[tokenId];
        }
    }
}