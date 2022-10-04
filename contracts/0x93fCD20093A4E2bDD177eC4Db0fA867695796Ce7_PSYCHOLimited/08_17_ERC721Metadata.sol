// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity ^0.8.4;

import "../ERC721.sol";
import "../../interface/metadata/IERC721Metadata.sol";
import "../../library/Encode.sol";

contract ERC721Metadata is ERC721, IERC721Metadata {
    string private _name;
    string private _symbol;
    string private _defaultExtension;
    mapping(uint256 => string) private _customExtension;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
        _defaultExtension = "";
    }

    function name()
        public
        view
        virtual
        override(IERC721Metadata)
        returns (string memory)
    {
        return _name;
    }

    function symbol()
        public
        view
        virtual
        override(IERC721Metadata)
        returns (string memory)
    {
        return _symbol;
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        virtual
        override(IERC721Metadata)
        returns (string memory)
    {
        bytes memory core = _coreTokenURI(_tokenId);
        bytes memory extension;
        if (
            Encode.toBytes32(_customExtension[_tokenId]) == Encode.toBytes32("")
        ) {
            if (Encode.toBytes32(_defaultExtension) == Encode.toBytes32("")) {
                delete extension;
            } else {
                delete extension;
                core = _defaultExtensionTokenURI(_tokenId);
            }
        } else {
            extension = abi.encodePacked(
                ",",
                _customExtensionTokenURI(_tokenId)
            );
        }
        bytes memory data = abi.encodePacked("{", core, extension, "}");
        if (ownerOf(_tokenId) == address(0)) {
            return "INVALID_ID";
        } else {
            return
                string(
                    abi.encodePacked(
                        "data:application/json;base64,",
                        Encode.toBase64(data)
                    )
                );
        }
    }

    function _coreTokenURI(uint256 _tokenId)
        internal
        view
        virtual
        returns (bytes memory)
    {
        return
            abi.encodePacked(
                '"name":"',
                name(),
                " #",
                Encode.toString(_tokenId),
                '"'
            );
    }

    function _defaultExtensionTokenURI(uint256 _tokenId)
        internal
        view
        virtual
        returns (bytes memory)
    {
        return
            abi.encodePacked(
                _coreTokenURI(_tokenId),
                ",",
                _defaultExtensionString()
            );
    }

    function _customExtensionTokenURI(uint256 _tokenId)
        internal
        view
        virtual
        returns (bytes memory)
    {
        return abi.encodePacked(_customExtensionString(_tokenId));
    }

    function _defaultExtensionString()
        internal
        view
        virtual
        returns (string memory)
    {
        return _defaultExtension;
    }

    function _customExtensionString(uint256 _tokenId)
        internal
        view
        virtual
        returns (string memory)
    {
        return _customExtension[_tokenId];
    }

    function _setDefaultExtension(string memory _extension) internal virtual {
        _defaultExtension = _extension;
    }

    function _setCustomExtension(string memory _extension, uint256 _tokenId)
        internal
        virtual
    {
        _customExtension[_tokenId] = _extension;
    }
}