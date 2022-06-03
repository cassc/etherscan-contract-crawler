// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/extensions/ERC1155URIStorage.sol)

pragma solidity ^0.8.0;

import "./ERC1155V2.sol";

/**
 * @dev ERC1155 token with storage based token URI management.
 */
abstract contract ERC1155URIStorage is ERC1155 {
    using Strings for uint256;

    // Optional base URI
    string private _baseURI = "";

    // Optional mapping for token URIs
    mapping(uint256 => string) private _tokenURIs;

    /**
     * @dev See {IERC1155Metadata-uri}.
     */
    function uri(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        string memory tokenURI = _tokenURIs[tokenId];

        // If token URI is set, concatenate base URI and tokenURI (via abi.encodePacked).
        return
            bytes(tokenURI).length > 0
                ? string(abi.encodePacked(_baseURI, tokenURI))
                : super.uri(tokenId);
    }

    /**
     * @dev Sets `_tokenURI` as the tokenURI of `tokenId`.
     *
     */
    function _setTokenURI(uint256 tokenId, string memory _tokenURI)
        internal
        virtual
    {
        _tokenURIs[tokenId] = _tokenURI;
        emit URI(_tokenURI, tokenId);
    }

    /**
     * @dev Sets a batch of `_tokenURI` as the tokenURI of `tokenId`.
     *
     */
    function _setTokenURIBatch(
        uint256[] memory tokenIds,
        string[] memory tokenURIs
    ) internal virtual {
        require(
            tokenIds.length == tokenURIs.length,
            "ERC1155URIStorage: tokenIds and tokenURIs length mismatch"
        );
        for (uint256 i = 0; i < tokenIds.length; i++) {
            _tokenURIs[tokenIds[i]] = tokenURIs[i];
        }
        emit BatchURI(tokenURIs, tokenIds);
    }

    /**
     * @dev Sets `baseURI` as the `_baseURI` for all tokens
     */
    function _setBaseURI(string memory baseURI) internal virtual {
        _baseURI = baseURI;
    }
}