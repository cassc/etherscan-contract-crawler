// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

/**
 * @dev ERC1155 token with storage based token URI management.
 */
abstract contract ERC1155Metadata is ERC1155 {
    using Strings for uint256;

    // Optional mapping for token URIs
    mapping(uint256 => string) private _tokenURIs;

    string private _contractURI;

    function contractURI() public view virtual returns (string memory) {
        return _contractURI;
    }

    function uri(uint256 id)
        public
        view
        virtual
        override
        returns (string memory)
    {
        string memory _tokenURI = _tokenURIs[id];

        // If there is a token URI, return it
        if (bytes(_tokenURI).length > 0) return _tokenURI;

        return string(abi.encodePacked(super.uri(id), id.toString()));
    }

    // INTERNAL FUNCTIONS

    /**
     * @dev Sets `_contractURI` as the contractURI
     */
    function _setContractURI(string memory contractURI_) internal virtual {
        _contractURI = contractURI_;
    }

    /**
     * @dev Sets `_tokenURI` as the tokenURI of `tokenId`.
     */
    function _setTokenURI(uint256 tokenId, string memory _tokenURI)
        internal
        virtual
    {
        _tokenURIs[tokenId] = _tokenURI;
    }
}