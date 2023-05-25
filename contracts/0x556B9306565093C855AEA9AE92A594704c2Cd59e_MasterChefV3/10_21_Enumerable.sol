// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.10;

/**
 * @notice This codes were copied from https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC721/extensions/ERC721Enumerable.sol, and did some changes.
 * @dev This implements an optional extension of defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */

abstract contract Enumerable {
    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    function tokenOfOwnerByIndex(address owner, uint256 index) public view returns (uint256) {
        require(index < _balances[owner], "Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    function balanceOf(address owner) public view returns (uint256) {
        require(owner != address(0), "Enumerable: address zero is not a valid owner");
        return _balances[owner];
    }

    function addToken(address from, uint256 tokenId) internal {
        _addTokenToOwnerEnumeration(from, tokenId);
        unchecked {
            _balances[from] += 1;
        }
    }

    function removeToken(address from, uint256 tokenId) internal {
        _removeTokenFromOwnerEnumeration(from, tokenId);
        unchecked {
            _balances[from] -= 1;
        }
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = _balances[to];
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
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

        uint256 lastTokenIndex = _balances[from] - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];
        require(tokenId == _ownedTokens[from][tokenIndex], "Invalid tokenId");
        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }
}