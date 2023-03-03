// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

/**
 * @dev ERC721A token with storage based token URI management.
 */
abstract contract ERC721Metadata is ERC721 {
    using Strings for uint256;

    // Optional mapping for token URIs
    mapping(uint256 => string) private _tokenURIs;

    string private _uri;
    string private _contractURI;

    function contractURI() public view virtual returns (string memory) {
        return _contractURI;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "URI query for nonexistent token");

        string memory _tokenURI = _tokenURIs[tokenId];

        // If there is a token URI, return it
        if (bytes(_tokenURI).length > 0) return _tokenURI;

        return super.tokenURI(tokenId);
    }

    // INTERNAL FUNCTIONS

    function _baseURI() internal view virtual override returns (string memory) {
        return _uri;
    }

    function _setBaseURI(string memory uri) internal virtual {
        _uri = uri;
    }

    function _setContractURI(string memory contractURI_) internal virtual {
        _contractURI = contractURI_;
    }

    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        require(_exists(tokenId), "URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
    }
}