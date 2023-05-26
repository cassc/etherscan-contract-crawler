// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {ERC721} from "../ERC721.sol";

error QueryForNonexistentToken(string method);

abstract contract ERC721Metadata is ERC721 {

    mapping(uint256 => string) private _tokenURI;


    string internal _uri;


    function _baseURI() internal override(ERC721) view virtual returns (string memory) {
        return _uri;
    }

    function setBaseURI(string memory uri) public onlyOwner virtual {
        _uri = uri;
    }

    function setTokenURI(uint256 tokenId, string memory uri) public onlyOwner virtual {
        if (!_exists(tokenId)) {
            revert QueryForNonexistentToken({ method: 'setTokenURI' });
        }

        _tokenURI[tokenId] = uri;
    }

    function tokenURI(uint256 tokenId) override(ERC721) public view virtual returns(string memory) {
        if (!_exists(tokenId)) {
            revert QueryForNonexistentToken({ method: 'tokenURI' });
        }

        string memory base = _baseURI();
        string memory token = _tokenURI[tokenId];

        if (bytes(token).length == 0) {
            token = _toString(tokenId);
        }

        if (bytes(base).length != 0) {
            return string(abi.encodePacked(base, token));
        }

        return '';
    }
}