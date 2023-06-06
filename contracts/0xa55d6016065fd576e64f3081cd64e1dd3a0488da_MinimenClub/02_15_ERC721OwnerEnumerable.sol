// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/ERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../ERC721.sol";
import "./IERC721Enumerable.sol";

error IndexOverOwnerBalance();
error IndexOverTokenCount();
error InvalidRange();
error MethodDisabled();
error QueryForZeroAddress();

/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 *
 * To save gas {tokenByIndex} is disabled because it increases mint cost by ~40%.
 */
abstract contract ERC721OwnerEnumerable is ERC721, IERC721Enumerable {
    // Must be populated for {tokenOfOwnerByIndex} to work.
    uint128 internal _minTokenId;
    uint128 internal _maxTokenId;

    // Tracks the total supply.
    uint256 internal _totalSupply;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(IERC165, ERC721)
        returns (bool)
    {
        return
            interfaceId == type(IERC721Enumerable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev To save gas, this is not explicity checked when minting a tokenId,
     * It is the responsibility of the extending contracts to make sure this is not exceeded
     * If they want Enumerable to work properly.
     *
     * The range includes the minId but excludes the maxId.
     */
    function _setTokenRange(uint256 minId, uint256 maxId) internal {
        if (_minTokenId > _maxTokenId) revert InvalidRange();
        _minTokenId = uint128(minId);
        _maxTokenId = uint128(maxId);
    }

    /**
     * @dev helpler function for valid mintIds
     */
    function _tokenIdInRange(uint256 tokenId) internal view returns (bool) {
        return
            uint128(tokenId) >= _minTokenId && uint128(tokenId) <= _maxTokenId;
    }

    /**
     * @dev helpler function for total tokens within the range
     */
    function _tokenLimit() internal view returns (uint256) {
        return _maxTokenId - _minTokenId + 1;
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index)
        public
        view
        virtual
        override
        returns (uint256)
    {
        if (index >= balanceOf(owner)) revert IndexOverOwnerBalance();
        if (owner == address(0)) revert QueryForZeroAddress();
        if (_maxTokenId == 0) revert MethodDisabled();
        uint256 tokenIdsIdx = 0;

        for (uint256 i = _minTokenId; i <= _maxTokenId; i++) {
            address tokenOwner = _owners[i];
            if (tokenOwner == owner) {
                if (tokenIdsIdx == index) {
                    return i;
                }
                tokenIdsIdx++;
            }
        }
        revert IndexOverOwnerBalance();
    }

    /**
     * @dev Since {tokenOfOwnerByIndex} would repeat work to get all tokenIds of an address, this method
     * is included to speed it to an O(n) instead of a O(n ** 2) operation.
     */
    function tokensOfOwner(address owner)
        public
        view
        virtual
        returns (uint256[] memory)
    {
        if (owner == address(0)) revert QueryForZeroAddress();
        if (_maxTokenId == 0) revert MethodDisabled();

        uint256[] memory tokenIds = new uint256[](balanceOf(owner));
        uint256 index = 0;

        for (uint256 i = _minTokenId; i <= _maxTokenId; i++) {
            address tokenOwner = _owners[i];
            if (tokenOwner == owner) {
                tokenIds[index] = i;
                index++;
            }
        }
        return tokenIds;
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256)
        public
        view
        virtual
        override
        returns (uint256)
    {
        revert MethodDisabled();
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (from == address(0)) {
            _totalSupply += 1;
        }

        if (to == address(0)) {
            _totalSupply -= 1;
        }
    }
}