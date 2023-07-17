// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import {ERC721A} from "@ERC721A/contracts/ERC721A.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

abstract contract ERC721AURIStorage is ERC721A {
    using Strings for uint256;

    /// @notice Optional mapping for token URIs
    mapping(uint256 => string) private _tokenURIs;
    /// @notice Base token URI
    string internal _baseTokenURI;
    /// @notice Whether or not to override individually set tokenURIs
    bool internal _forceBaseTokenURI;

    /// @dev See {IERC721Metadata-tokenURI}.
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        if (!_forceBaseTokenURI) {
            string memory _tokenURI = _tokenURIs[tokenId];

            // If URI has been set for token, return it
            if (bytes(_tokenURI).length > 0) {
                return _tokenURI;
            }
        }

        return super.tokenURI(tokenId);
    }

    /// @notice Sets the base token URI
    /// @param baseTokenURI The base token URI
    function _setBaseTokenURI(string memory baseTokenURI) internal {
        _baseTokenURI = baseTokenURI;
    }

    /// @notice Sets whether or not to override individually set tokenURIs with the base URI
    function _setForceBaseTokenURI(bool forceBaseTokenURI) internal {
        _forceBaseTokenURI = forceBaseTokenURI;
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    /// @notice Sets the token URI for a given token ID
    /// @param tokenId The token ID to set the token URI for
    /// @param _tokenURI The token URI to set
    function _setTokenURI(uint256 tokenId, string memory _tokenURI)
        internal
        virtual
    {
        require(
            _exists(tokenId),
            "ERC721URIStorage: URI set of nonexistent token"
        );
        _tokenURIs[tokenId] = _tokenURI;
    }

    function _burn(uint256 tokenId) internal virtual override {
        super._burn(tokenId);

        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }
    }
}