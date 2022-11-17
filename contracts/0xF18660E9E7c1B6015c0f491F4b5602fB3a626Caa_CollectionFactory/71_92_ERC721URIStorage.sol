// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/extensions/ERC721URIStorage.sol)

pragma solidity 0.8.10;

import "./ERC721.sol";

/**
 * @title Appending URI storage utilities onto template ERC721 contract
 * @author [email protected] and OpenZeppelin
 * @dev ERC721 token with storage based token URI management. OpenZeppelin template edited by Highlight
 */
/* solhint-disable */
abstract contract ERC721URIStorage is ERC721 {
    using Strings for uint256;

    /**
     * @dev Optional token-grouping mapping for uris. Edition IDs / Token IDs depending on implementing contract
     */
    mapping(uint256 => string) internal _tokenURIs;

    /**
     * @dev Hashed rotation key data
     */
    bytes internal _hashedRotationKeyData;

    /**
     * @dev Hashed base uri data
     */
    bytes internal _hashedBaseURIData;

    /**
     * @dev Rotation key
     */
    uint256 internal _rotationKey;

    // TODO: change to support multiple baseURIs per contract, and multiple nextTokenIds / supplies
    /**
     * @dev Contract baseURI
     */
    string public baseURI;

    /**
     * @dev Set contract baseURI
     */
    function _setBaseURI(string calldata newBaseURI) internal {
        string memory currentBaseURI = _baseURI();
        require(bytes(currentBaseURI).length == 0, "Already set");
        require(bytes(newBaseURI).length > 0, "Empty string");

        baseURI = newBaseURI;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);

        string memory _tokenURI = _tokenURIs[tokenId];

        // If there is no token URI, return the base URI.
        if (bytes(_tokenURI).length == 0) {
            return super.tokenURI(tokenId);
        }

        return _tokenURI;
    }

    /**
     * @dev See {ERC721-_burn}. This override additionally checks to see if a
     * token-specific URI was set for the token, and if so, it deletes the token URI from
     * the storage mapping.
     */
    function _burn(uint256 tokenId) internal virtual override {
        super._burn(tokenId);

        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }
    }

    // just remove the original function in ERC721
    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }
}