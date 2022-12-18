// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: Copyright (C) 2022 Spanning Labs Inc.

pragma solidity ^0.8.0;

import "../SpanningERC721.sol";
import "./ISpanningERC721Enumerable.sol";

/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
abstract contract SpanningERC721Enumerable is
    SpanningERC721,
    ISpanningERC721Enumerable
{
    // Mapping from owner to list of owned token IDs
    mapping(bytes32 => mapping(uint256 => uint256)) private ownedTokens_;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private ownedTokensIndex_;

    // Array with all token ids, used for enumeration
    uint256[] private allTokens_;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private allTokensIndex_;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(IERC165, SpanningERC721)
        returns (bool)
    {
        return
            interfaceId == type(ISpanningERC721Enumerable).interfaceId ||
            super.supportsInterface(interfaceId);
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
        bytes32 derivedSpanningAddress = getAddressFromLegacy(owner);

        require(
            index < SpanningERC721.balanceOf(derivedSpanningAddress),
            "ERC721Enumerable: owner index out of bounds"
        );
        return ownedTokens_[derivedSpanningAddress][index];
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(bytes32 owner, uint256 index)
        public
        view
        virtual
        override
        returns (uint256)
    {
        require(
            index < SpanningERC721.balanceOf(owner),
            "ERC721Enumerable: owner index out of bounds"
        );
        return ownedTokens_[owner][index];
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return allTokens_.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index)
        public
        view
        virtual
        override
        returns (uint256)
    {
        require(
            index < SpanningERC721Enumerable.totalSupply(),
            "ERC721Enumerable: global index out of bounds"
        );
        return allTokens_[index];
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
        bytes32 senderAddress,
        bytes32 receiverAddress,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(senderAddress, receiverAddress, tokenId);

        if (senderAddress == bytes32(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (senderAddress != receiverAddress) {
            _removeTokenFromOwnerEnumeration(senderAddress, tokenId);
        }
        if (receiverAddress == bytes32(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (receiverAddress != senderAddress) {
            _addTokenToOwnerEnumeration(receiverAddress, tokenId);
        }
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param receiverAddress address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(
        bytes32 receiverAddress,
        uint256 tokenId
    ) private {
        uint256 length = SpanningERC721.balanceOf(receiverAddress);
        ownedTokens_[receiverAddress][length] = tokenId;
        ownedTokensIndex_[tokenId] = length;
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        allTokensIndex_[tokenId] = allTokens_.length;
        allTokens_.push(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `ownedTokensIndex_` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the ownedTokens_ array.
     * @param senderAddress address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(
        bytes32 senderAddress,
        uint256 tokenId
    ) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = SpanningERC721.balanceOf(senderAddress) - 1;
        uint256 tokenIndex = ownedTokensIndex_[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = ownedTokens_[senderAddress][lastTokenIndex];

            ownedTokens_[senderAddress][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            ownedTokensIndex_[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete ownedTokensIndex_[tokenId];
        delete ownedTokens_[senderAddress][lastTokenIndex];
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the allTokens_ array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = allTokens_.length - 1;
        uint256 tokenIndex = allTokensIndex_[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = allTokens_[lastTokenIndex];

        allTokens_[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        allTokensIndex_[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete allTokensIndex_[tokenId];
        allTokens_.pop();
    }
}