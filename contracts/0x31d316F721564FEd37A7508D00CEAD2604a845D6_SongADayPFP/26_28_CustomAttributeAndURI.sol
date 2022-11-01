// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

// import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "../BID721/BID721.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "./DecodeSegmentedURI.sol";

import "hardhat/console.sol";

/// @custom:security-contact [email protected]
abstract contract CustomAttributeAndURI is BID721, DecodeSegmentedURI {
    using ECDSA for bytes32;

    bytes4 internal _baseTokenURIPrefix;

    // Maps token ids to their URIs
    mapping(uint256 => bytes32) private _tokenURIs;

    // Maps token ids to their attributes
    mapping(uint256 => bytes32) private _tokenAttributes;

    // Inverses the map of token ids to attributes
    mapping(bytes32 => uint256) private _tokenAttributesToTokenIds;

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(tokenId), "URI query on nonexistent token");

        bytes32 thisTokenURI = _tokenURIs[tokenId];
        string memory base = _baseURI();

        if (thisTokenURI.length > 0) {
            string memory decodedTokenURI = _decodeTokenUri(thisTokenURI);

            // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
            if (bytes(base).length > 0) {
                return string(abi.encodePacked(base, decodedTokenURI));
            }

            // If there is no base URI, return the token URI.
            return string(abi.encodePacked(decodedTokenURI));
        }

        return super.tokenURI(tokenId);
    }

    function tokenAttribute(uint256 tokenId)
        public
        view
        virtual
        returns (bytes32)
    {
        require(_exists(tokenId), "attr query on nonexistent token");

        return _tokenAttributes[tokenId];
    }

    function tokenAttributeTokenId(bytes32 inputTokenAttribute)
        public
        view
        virtual
        returns (uint256)
    {
        require(
            tokenAttributeExists(inputTokenAttribute),
            "id query on nonexistent attr"
        );

        return _tokenAttributesToTokenIds[inputTokenAttribute];
    }

    function tokenAttributeExists(bytes32 inputTokenAttribute)
        public
        view
        virtual
        returns (bool)
    {
        return
            _tokenAttributes[_tokenAttributesToTokenIds[inputTokenAttribute]] ==
            inputTokenAttribute;
    }

    function getTokenURIAndAttributeHash(
        address approvedAddress,
        bytes32 inputTokenURI,
        bytes32 inputTokenAttribute
    ) public pure virtual returns (bytes32) {
        return keccak256(abi.encodePacked(approvedAddress, inputTokenURI, inputTokenAttribute));
    }

    function _setTokenURI(uint256 tokenId, bytes32 inputTokenURI)
        internal
        virtual
    {
        require(_exists(tokenId), "URI set on nonexistent token");
        _tokenURIs[tokenId] = inputTokenURI;
    }

    function _setTokenAttribute(uint256 tokenId, bytes32 inputTokenAttribute)
        internal
        virtual
    {
        require(_exists(tokenId), "attr set for nonexistent token");
        require(inputTokenAttribute > 0, "attr can't be 0");
        require(
            !tokenAttributeExists(inputTokenAttribute),
            "attr already in use"
        );

        _tokenAttributes[tokenId] = inputTokenAttribute;
        _tokenAttributesToTokenIds[inputTokenAttribute] = tokenId;
    }

    // function _burn(uint256 tokenId) internal virtual override {
    //     super._burn(tokenId);

    //     if (_tokenURIs[tokenId].length != 0) {
    //         delete _tokenURIs[tokenId];
    //     }

    //     if (_tokenAttributes[tokenId] != 0) {
    //         delete _tokenAttributesToTokenIds[_tokenAttributes[tokenId]];
    //         delete _tokenAttributes[tokenId];
    //     }
    // }

    function _baseURIPrefix() internal view virtual returns (bytes4) {
        return _baseTokenURIPrefix;
    }

    function _decodeTokenUri(bytes32 inputTokenURI)
        internal
        view
        returns (string memory decodedTokenURI)
    {
        return _combineURISegments(_baseURIPrefix(), inputTokenURI);
    }

    function _getTokenURIAndAttributeHashSigner(
        address approvedAddress,
        bytes32 inputTokenURI,
        bytes32 inputTokenAttribute,
        bytes calldata signature
    ) internal pure virtual returns (address) {
        bytes32 message = getTokenURIAndAttributeHash(
            approvedAddress,
            inputTokenURI,
            inputTokenAttribute
        );

        return message.toEthSignedMessageHash().recover(signature);
    }
}