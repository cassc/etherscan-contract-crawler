// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract ERC721AURIStorage is ERC721A {
    string baseURI;
    mapping(uint256 => string) private _tokenURIs;

    constructor(string memory name_, string memory symbol_) ERC721A(name_, symbol_) {}

    /**
     * @dev Get baseURI
    */
    function _baseURI() internal view override virtual returns (string memory) {
        return baseURI;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}
     */
    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721AURIStorage: the tokenId does not exist"
        );

        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = _baseURI();
        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        return string(string(abi.encodePacked(base, Strings.toString(tokenId))));
    }

    /**
     * @dev Sets `_tokenURI` as the tokenURI of `tokenId`
     * Requirments:
     *
     * - `tokenId` must exist
     */
    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal {
        require(_exists(tokenId), "ERC721AURIStorage: the tokenId does not exist");
        _tokenURIs[tokenId] = _tokenURI;
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId, bool approvalCheck) internal virtual override {
        super._burn(tokenId, approvalCheck);
        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }
    }
}