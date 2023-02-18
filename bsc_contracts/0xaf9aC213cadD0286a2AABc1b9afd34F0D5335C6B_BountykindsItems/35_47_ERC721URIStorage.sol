// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import { StringsUpgradeable, ERC721Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";

/**
 * @dev ERC721 token with storage based token URI management.
 */
abstract contract ERC721URIStorage is ERC721Upgradeable {
    using StringsUpgradeable for uint256;

    string internal _baseUri;

    function baseURI() external view returns (string memory) {
        return _baseURI();
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseUri;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);

        string memory baseUri = _baseUri;

        return bytes(baseUri).length > 0 ? string(abi.encodePacked(baseUri, tokenId.toString())) : "";
    }

    function _setBaseURI(string memory baseUri_) internal virtual {
        _baseUri = baseUri_;
    }

    uint256[49] private __gap;
}