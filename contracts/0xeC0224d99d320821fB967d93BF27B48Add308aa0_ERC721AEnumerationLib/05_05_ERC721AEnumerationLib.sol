//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/interfaces/IERC721.sol";

import "../interfaces/IERC721Enumerable.sol";


library ERC721AEnumerationLib {

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(ERC721EnumerableContract storage self, address owner, uint256 index) internal view returns (uint256) {
        require(index < IERC721(address(this)).balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return self._ownedTokens[owner][index];
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply(ERC721EnumerableContract storage self) internal view returns (uint256) {
        return self._allTokens.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(ERC721EnumerableContract storage self, uint256 index) internal view returns (uint256) {
        require(index < totalSupply(self), "ERC721Enumerable: global index out of bounds");
        return self._allTokens[index];
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(ERC721EnumerableContract storage self, address to, uint256 tokenId) internal {
        uint256 length = IERC721(address(this)).balanceOf(to);
        self._ownedTokens[to][length] = tokenId;
        self._ownedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(ERC721EnumerableContract storage self, uint256 tokenId) internal {
        self._allTokensIndex[tokenId] = self._allTokens.length;
        self._allTokens.push(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(ERC721EnumerableContract storage self, address from, uint256 tokenId) internal {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).
        uint256 lastTokenIndex = IERC721(address(this)).balanceOf(from) - 1;
        uint256 tokenIndex = self._ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = self._ownedTokens[from][lastTokenIndex];

            self._ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            self._ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete self._ownedTokensIndex[tokenId];
        delete self._ownedTokens[from][lastTokenIndex];
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(ERC721EnumerableContract storage self, uint256 tokenId) internal {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).
        uint256 lastTokenIndex = self._allTokens.length - 1;
        uint256 tokenIndex = self._allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = self._allTokens[lastTokenIndex];

        self._allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        self._allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete self._allTokensIndex[tokenId];
        self._allTokens.pop();
    }

}