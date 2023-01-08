// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "./ERC721ABaseInternal.sol";
import "./IERC721ABase.sol";

/**
 * @dev Adopted from ERC721AUpgradeable to remove name(), symbol(), tokenURI() and supportsInterface() as they'll be provided by independent facets.
 */
contract ERC721ABase is ERC721ABaseInternal, IERC721ABase {
    /**
     * @inheritdoc IERC721ABase
     */
    function balanceOf(address owner) external view virtual returns (uint256) {
        return _balanceOf(owner);
    }

    /**
     * @inheritdoc IERC721ABase
     */
    function ownerOf(uint256 tokenId) external view virtual returns (address) {
        return _ownerOf(tokenId);
    }

    /**
     * @inheritdoc IERC721ABase
     */
    function approve(address to, uint256 tokenId) public virtual {
        _approve(to, tokenId);
    }

    /**
     * @inheritdoc IERC721ABase
     */
    function getApproved(uint256 tokenId) external view virtual override returns (address) {
        return _getApproved(tokenId);
    }

    /**
     * @inheritdoc IERC721ABase
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(operator, approved);
    }

    /**
     * @inheritdoc IERC721ABase
     */
    function isApprovedForAll(address owner, address operator) external view virtual override returns (bool) {
        return _isApprovedForAll(owner, operator);
    }

    /**
     * @inheritdoc IERC721ABase
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        _transferFrom(from, to, tokenId);
    }

    /**
     * @inheritdoc IERC721ABase
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        _safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @inheritdoc IERC721ABase
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata _data
    ) public virtual override {
        _safeTransferFrom(from, to, tokenId, _data);
    }
}