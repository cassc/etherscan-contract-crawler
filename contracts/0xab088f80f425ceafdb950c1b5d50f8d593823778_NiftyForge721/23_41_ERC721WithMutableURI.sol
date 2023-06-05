// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import '@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol';
import '@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol';

import './IERC721WithMutableURI.sol';

/// @dev This is a contract used to add mutableURI to the contract
/// @author Simon Fremaux (@dievardump)
contract ERC721WithMutableURI is IERC721WithMutableURI, ERC721Upgradeable {
    using StringsUpgradeable for uint256;

    // base mutable meta URI
    string public baseMutableURI;

    mapping(uint256 => string) private _tokensMutableURIs;

    /// @notice See {ERC721WithMutableURI-mutableURI}.
    function mutableURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(tokenId), '!UNKNOWN_TOKEN!');

        string memory _tokenMutableURI = _tokensMutableURIs[tokenId];
        string memory base = _baseMutableURI();

        // If both are set, concatenate the baseURI and mutableURI (via abi.encodePacked).
        if (bytes(base).length > 0 && bytes(_tokenMutableURI).length > 0) {
            return string(abi.encodePacked(base, _tokenMutableURI));
        }

        // If only token mutable URI is set
        if (bytes(_tokenMutableURI).length > 0) {
            return _tokenMutableURI;
        }

        // else return base + tokenId
        return
            bytes(base).length > 0
                ? string(abi.encodePacked(base, tokenId.toString()))
                : '';
    }

    /// @dev helper to get the base for mutable meta
    /// @return the base for mutable meta uri
    function _baseMutableURI() internal view returns (string memory) {
        return baseMutableURI;
    }

    /// @dev Set the base mutable meta URI
    /// @param baseMutableURI_ the new base for mutable meta uri used in mutableURI()
    function _setBaseMutableURI(string memory baseMutableURI_) internal {
        baseMutableURI = baseMutableURI_;
    }

    /// @dev Set the mutable URI for a token
    /// @param tokenId the token id
    /// @param mutableURI_ the new mutableURI for tokenId
    function _setMutableURI(uint256 tokenId, string memory mutableURI_)
        internal
    {
        if (bytes(mutableURI_).length == 0) {
            if (bytes(_tokensMutableURIs[tokenId]).length > 0) {
                delete _tokensMutableURIs[tokenId];
            }
        } else {
            _tokensMutableURIs[tokenId] = mutableURI_;
        }
    }
}