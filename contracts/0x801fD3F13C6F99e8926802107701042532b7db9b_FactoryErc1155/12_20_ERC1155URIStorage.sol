// SPDX-License-Identifier: MIT

pragma solidity 0.8.1;

import "openzeppelin-solidity/contracts/token/ERC1155/ERC1155.sol";
import "openzeppelin-solidity/contracts/utils/Strings.sol";

abstract contract ERC1155URIStorage is ERC1155 {
    using Strings for uint256;

    string private baseUri;

    // Optional mapping for token URIs
    mapping (uint256 => string) private _tokenURIs;

    mapping (uint256 => bool) private _tokenIds;

    function tokenURI(uint256 tokenId) public view virtual returns (string memory) {
        require(_tokenIds[tokenId], "ERC1155URIStorage: URI query for nonexistent token");

        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = _baseURI();

        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }

        return super.uri(tokenId);
    }

    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        require(_tokenIds[tokenId], "ERC1155URIStorage: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
    }

    function _setBaseUri(string memory _uri) internal virtual {
        //require(_uri != "", "");
        baseUri = _uri;
    }

    function _baseURI() internal view virtual returns (string memory) {
        return baseUri;
    }

    function _markTokenId(uint256 id) internal virtual {
        _tokenIds[id] = true;
    }
}