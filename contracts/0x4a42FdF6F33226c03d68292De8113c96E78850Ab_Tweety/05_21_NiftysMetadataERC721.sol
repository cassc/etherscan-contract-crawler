// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/utils/Strings.sol';
import '@openzeppelin/contracts/token/ERC721/ERC721.sol';

/**
 * @dev ERC721 token with storage based token URI management.
 */
abstract contract NiftysMetadataERC721 is ERC721 {
    using Strings for uint256;
    mapping(uint256 => string) private _tokenURIs;

    string private _uri;
    string private _contractURI;

    function contractURI() public view virtual returns (string memory) {
        return _contractURI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _uri;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), 'ERC721URIStorage: URI query for nonexistent token');

        string memory _tokenURI = _tokenURIs[tokenId];

        // If token has optional URI mapping, return it
        if (bytes(_tokenURI).length > 0) return _tokenURI;

        return super.tokenURI(tokenId);
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