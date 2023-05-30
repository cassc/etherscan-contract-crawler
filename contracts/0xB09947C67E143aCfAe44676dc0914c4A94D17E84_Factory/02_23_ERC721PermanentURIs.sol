// SPDX-License-Identifier: MIT
// OpenGem Contracts (token/ERC721/extensions/ERC721PermanentURIs.sol)

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

abstract contract ERC721PermanentURIs is ERC721 {
    using Strings for uint256;

    string[] private _globalURIsPermanent;

    mapping(uint256 => string[]) private _tokenURIsPermanent;

    uint256 _baseURIsPermanentIndex = 0;
    mapping(uint256 => string) private _prefixBaseURIsPermanent;
    mapping(uint256 => string) private _suffixBaseURIsPermanent;

    function tokenURIsPermanent(uint256 tokenId) public view virtual returns (string[] memory) {
        _requireMinted(tokenId);
        uint256 index = 0;
        string[] memory uris = new string[](_globalURIsPermanent.length + _baseURIsPermanentIndex + _tokenURIsPermanent[tokenId].length);

        for (uint256 i = 0; i < _globalURIsPermanent.length;) {
            uris[index] = string(_globalURIsPermanent[i]);
            unchecked {
                index++;
                i++;
            }
        }

        for (uint256 i = 0; i < _baseURIsPermanentIndex;) {
            uris[index] = string(abi.encodePacked(_prefixBaseURIsPermanent[i], tokenId.toString(), _suffixBaseURIsPermanent[i]));
            unchecked {
                index++;
                i++;
            }
        }

        for (uint256 i = 0; i < _tokenURIsPermanent[tokenId].length;) {
            uris[index] = string(_tokenURIsPermanent[tokenId][i]);
            unchecked {
                index++;
                i++;
            }
        }

        return uris;
    }

    function _addPermanentBaseURI(string memory prefixURI_, string memory suffixURI_) internal virtual {
        _prefixBaseURIsPermanent[_baseURIsPermanentIndex] = prefixURI_;
        _suffixBaseURIsPermanent[_baseURIsPermanentIndex] = suffixURI_;
        _baseURIsPermanentIndex++;
    }

    function _addPermanentTokenURI(uint256 tokenId, string memory tokenURI_) internal virtual {
        require(_exists(tokenId), "ERC721PermanentURIs: PermanentURI set of nonexistent token");
        _tokenURIsPermanent[tokenId].push(tokenURI_);
    }

    function _addPermanentGlobalURI(string memory tokenURI_) internal virtual {
        _globalURIsPermanent.push(tokenURI_);
    }

    function _burn(uint256 tokenId) internal virtual override {
        super._burn(tokenId);

        if (_tokenURIsPermanent[tokenId].length != 0) {
            delete _tokenURIsPermanent[tokenId];
        }
    }
}