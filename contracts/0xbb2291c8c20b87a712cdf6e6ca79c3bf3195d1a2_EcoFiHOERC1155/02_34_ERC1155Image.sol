// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";

contract ERC1155Image {
    using StringsUpgradeable for uint;

    // Optional mapping for token URIs
    mapping (uint256 => string) private _tokenImages;

    event Image(string value, uint256 indexed id);

    function image(uint id) external view virtual returns (string memory) {
        return _tokenImage(id);
    }

    function _tokenImage(uint256 tokenId) internal view virtual returns (string memory) {
        string memory tokenImage = _tokenImages[tokenId];
        return tokenImage;
    }

    /**
     * @dev Sets `_tokenImage` as the tokenImage of `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _setTokenImage(uint256 tokenId, string memory _image) internal virtual {
        _tokenImages[tokenId] = _image;
        emit Image(_tokenImage(tokenId), tokenId);
    }

    function _clearTokenImages(uint256 tokenId) internal {
        if (bytes(_tokenImages[tokenId]).length != 0) {
            delete _tokenImages[tokenId];
        }
    }
    uint256[50] private __gap;
}