// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

import "@openzeppelin/contracts/utils/Strings.sol";
import "./IDisplayURISwitchable.sol";

abstract contract DisplayURISwitchable is IDisplayURISwitchable {
    using Strings for uint256;

    mapping(uint256 => bool) internal _displayFullMode;
    string internal _tokenOriginalBaseURI;
    string internal _tokenDisplayBaseURI;

    function _setBaseURI(string memory baseURI) internal {
        require(_hasLength(baseURI), "Need a valid URI.");

        _tokenOriginalBaseURI = baseURI;
    }

    function _setDisplayBaseURI(string memory baseURI) internal {
        require(_hasLength(baseURI), "Need a valid URI.");

        _tokenDisplayBaseURI = baseURI;
    }

    function _setDisplayMode(uint256 tokenId, bool mode) internal {
        _displayFullMode[tokenId] = mode;
    }

    function tokenDisplayFullMode(uint256 tokenId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return _displayFullMode[tokenId];
    }

    function originalTokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        return _createURI(_tokenOriginalBaseURI, tokenId);
    }

    function displayTokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        return _createURI(_tokenDisplayBaseURI, tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        bool modeFull = _displayFullMode[tokenId];

        if (modeFull) {
            return displayTokenURI(tokenId);
        }

        return originalTokenURI(tokenId);
    }

    function _hasLength(string memory str) internal pure returns (bool) {
        return bytes(str).length > 0;
    }

    function _createURI(string memory baseURI, uint256 tokenId)
        internal
        pure
        returns (string memory)
    {
        if (_hasLength(baseURI)) {
            return string(abi.encodePacked(baseURI, tokenId.toString()));
        }

        return "";
    }
}