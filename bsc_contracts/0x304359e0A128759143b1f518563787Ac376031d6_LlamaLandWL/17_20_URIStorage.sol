// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../node_modules/@openzeppelin/contracts/utils/Strings.sol";

abstract contract URIStorage {
    using Strings for uint256;
    mapping(uint256 => string) private _tokenURIs;

    function addUri(uint256 tokenId, string memory uri) internal {
        require(bytes(_tokenURIs[tokenId]).length == 0, 'URIStorage: Token ID has existed');
        _tokenURIs[tokenId] = uri;
    }

    function updateUri(uint256 tokenId, string memory uri) internal {
        require(bytes(_tokenURIs[tokenId]).length > 0, 'URIStorage: Token ID does not exist');
        _tokenURIs[tokenId] = uri;
    }

    function getUri(uint256 tokenId) internal view returns (string memory) {
        return _tokenURIs[tokenId];
    }
}