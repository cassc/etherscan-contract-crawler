// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '../721ALib/ERC721A.sol';
import '@openzeppelin/contracts/utils/Strings.sol';

/**
 * @dev ERC721A token with storage based token URI management.
 */
abstract contract NiftysMetadataERC721A is ERC721A {
    using Strings for uint256;

    // Optional mapping for token URIs
    mapping(uint256 => string) private _tokenURIs;

    string private _uri;
    string private _contractURI;

    function contractURI() public view virtual returns (string memory) {
        return _contractURI;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), 'ERC721URIStorage: URI query for nonexistent token');

        string memory _tokenURI = _tokenURIs[tokenId];

        // If token has optional URI mapping, return it
        if (bytes(_tokenURI).length > 0) return _tokenURI;

        return super.tokenURI(tokenId);
    }

    // INTERNAL FUNCTIONS

    /**
     * @dev Returns `_uri` for internal functions
     *
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return _uri;
    }

    /**
     * @dev Sets `_uri` as the uri
     *
     */
    function _setBaseURI(string memory uri) internal virtual {
        _uri = uri;
    }

    /**
     * @dev Sets `_contractURI` as the contractURI
     *
     */
    function _setContractURI(string memory contractURI_) internal virtual {
        _contractURI = contractURI_;
    }

    /**
     * @dev Sets `_tokenURI` as the tokenURI of `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        require(_exists(tokenId), 'ERC721URIStorage: URI set of nonexistent token');
        _tokenURIs[tokenId] = _tokenURI;
    }
}