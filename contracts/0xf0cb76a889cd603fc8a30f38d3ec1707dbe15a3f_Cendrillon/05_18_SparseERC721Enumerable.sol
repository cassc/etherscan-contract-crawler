// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./SparseERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
abstract contract SparseERC721Enumerable is SparseERC721, IERC721Enumerable {
    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _sparseOwnedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _sparseOwnedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _sparseAllTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _sparseAllTokensIndex;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, SparseERC721) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < SparseERC721.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        if(owner == Ownable.owner() && index < SparseERC721.nrOfTokensInitiallyOwnedByContractOwner()) {
            return SparseERC721.tokenInitiallyOwnedByContractOwnerByIndex(index);
        } else {
            return _sparseOwnedTokens[owner][index - (owner == Ownable.owner() ? SparseERC721.nrOfTokensInitiallyOwnedByContractOwner() : 0)];
        }
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return SparseERC721.nrOfTokensInitiallyOwnedByContractOwner() + _sparseAllTokens.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < SparseERC721Enumerable.totalSupply(), "ERC721Enumerable: global index out of bounds");
        if(index < SparseERC721.nrOfTokensInitiallyOwnedByContractOwner()) {
            return SparseERC721.tokenInitiallyOwnedByContractOwnerByIndex(index);
        } else {
            return _sparseAllTokens[index - SparseERC721.nrOfTokensInitiallyOwnedByContractOwner()];
        }
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
            if(to == Ownable.owner() && tokenId >= 1 && tokenId <= 1024) {
                // Case handled separately by base token
            } else {
                _addTokenToAllTokensEnumeration(tokenId);
            }
        } else if (from != to) {
            if(from == Ownable.owner() && tokenId >= 1 && tokenId <= 1024) {
                // Case handled separately by base token
            } else {
                _removeTokenFromOwnerEnumeration(from, tokenId);
            }
        }
        if (to == address(0)) {
            if(from == Ownable.owner() && tokenId >= 1 && tokenId <= 1024) {
                // Case handled separately by base token
            } else {
                _removeTokenFromAllTokensEnumeration(tokenId);
            }
        } else if (to != from) {
            if(to == Ownable.owner() && tokenId >= 1 && tokenId <= 1024) {
                // Case handled separately by base token
            } else {
                _addTokenToOwnerEnumeration(to, tokenId);
            }
        }
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = SparseERC721.balanceOf(to) - (to == Ownable.owner() ? SparseERC721.nrOfTokensInitiallyOwnedByContractOwner() : 0);
        
        _sparseOwnedTokens[to][length] = tokenId;
        _sparseOwnedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _sparseAllTokensIndex[tokenId] = _sparseAllTokens.length;
        _sparseAllTokens.push(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = SparseERC721.balanceOf(from) - 1 - (from == Ownable.owner() ? SparseERC721.nrOfTokensInitiallyOwnedByContractOwner() : 0);
        uint256 tokenIndex = _sparseOwnedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _sparseOwnedTokens[from][lastTokenIndex];

            _sparseOwnedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _sparseOwnedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _sparseOwnedTokensIndex[tokenId];
        delete _sparseOwnedTokens[from][lastTokenIndex];
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _sparseAllTokens.length - 1;
        uint256 tokenIndex = _sparseAllTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _sparseAllTokens[lastTokenIndex];

        _sparseAllTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _sparseAllTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _sparseAllTokensIndex[tokenId];
        _sparseAllTokens.pop();
    }
}