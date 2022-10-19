// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/ERC721Enumerable.sol)
pragma solidity ^0.8.0;


import "@openzeppelin/contracts/interfaces/IERC721.sol";

import "../libraries/ERC721ALib.sol";
import "../libraries/ERC721AEnumerationLib.sol";

import "../interfaces/IERC721Enumerable.sol";

import "../utilities/Modifiers.sol";

/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
contract ERC721EnumerableFacet is Modifiers {

    using ERC721AEnumerationLib for ERC721EnumerableContract;

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view virtual returns (uint256) {
        ERC721EnumerableContract storage ds = ERC721ALib.erc721aStorage().enumerations;
        return ds.tokenOfOwnerByIndex(owner, index);
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) external view virtual returns (uint256) {
        ERC721EnumerableContract storage ds = ERC721ALib.erc721aStorage().enumerations;
        return ds.tokenByIndex(index);
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) internal {
        ERC721EnumerableContract storage ds = ERC721ALib.erc721aStorage().enumerations;
        return ds._addTokenToOwnerEnumeration(to, tokenId);
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) internal {
        ERC721EnumerableContract storage ds = ERC721ALib.erc721aStorage().enumerations;
        return ds._addTokenToAllTokensEnumeration(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) internal {
        ERC721EnumerableContract storage ds = ERC721ALib.erc721aStorage().enumerations;
        return ds._removeTokenFromOwnerEnumeration(from, tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) internal {
        ERC721EnumerableContract storage ds = ERC721ALib.erc721aStorage().enumerations;
        return ds._removeTokenFromAllTokensEnumeration(tokenId);
    }
    
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal {
        ERC721EnumerableContract storage ds = ERC721ALib.erc721aStorage().enumerations;
        if (from == address(0)) {
            ds._addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            ds._removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            ds._removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            ds._addTokenToOwnerEnumeration(to, tokenId);
        }
    }

}