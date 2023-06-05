// SPDX-License-Identifier: BUSL-1.1
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/ERC721Enumerable.sol)

pragma solidity ^0.8.0;

import {ERC1155} from "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";

import {IERC1155Enumerable} from "../interfaces/IERC1155Enumerable.sol";

/// Extension of {ERC1155} that adds
/// enumerability of all the token ids in the contract as well as all token ids owned by each
/// account.
abstract contract ERC1155Enumerable is IERC1155Enumerable, ERC1155 {
  // Mapping from owner to list of owned token IDs
  mapping(address => uint256[]) private _ownedTokens; // An index of all tokens

  // Mapping from address to token ID to index of the owner tokens list
  mapping(address => mapping(uint256 => uint256)) private _ownedTokensIndex;

  mapping(uint256 => uint256) private _idTotalSupply;

  // Array with all token ids, used for enumeration
  uint256[] private _allTokens;

  // Mapping from token id to position in the allTokens array
  mapping(uint256 => uint256) private _allTokensIndex;

  /// @inheritdoc IERC1155Enumerable
  function tokenOfOwnerByIndex(address owner, uint256 index) external view override returns (uint256) {
    return _ownedTokens[owner][index];
  }

  /// @inheritdoc IERC1155Enumerable
  function totalIds() external view override returns (uint256) {
    return _allTokens.length;
  }

  /// @inheritdoc IERC1155Enumerable
  function totalSupply(uint256 id) external view override returns (uint256) {
    return _idTotalSupply[id];
  }

  /// @inheritdoc IERC1155Enumerable
  function tokenByIndex(uint256 index) external view override returns (uint256) {
    return _allTokens[index];
  }

  /// @dev Hook that is called before any token transfer. This includes minting
  /// and burning.
  function _beforeTokenTransfer(
    address,
    address from,
    address to,
    uint256[] memory ids,
    uint256[] memory amounts,
    bytes memory
  ) internal virtual override {
    for (uint256 i; i < ids.length; ) {
      if (amounts[i] != 0) _addTokenEnumeration(from, to, ids[i], amounts[i]);

      unchecked {
        ++i;
      }
    }
  }

  /// @dev Add token enumeration list if necessary.
  function _addTokenEnumeration(address from, address to, uint256 id, uint256 amount) internal {
    if (from == address(0)) {
      if (_idTotalSupply[id] == 0 && _additionalConditionAddTokenToAllTokensEnumeration(id))
        _addTokenToAllTokensEnumeration(id);
      _idTotalSupply[id] += amount;
    }

    if (to != address(0) && to != from) {
      if (balanceOf(to, id) == 0 && _additionalConditionAddTokenToOwnerEnumeration(to, id))
        _addTokenToOwnerEnumeration(to, id);
    }
  }

  /// @dev Any additional condition to add token enumeration when overridden.
  function _additionalConditionAddTokenToAllTokensEnumeration(uint256) internal virtual returns (bool) {
    return true;
  }

  /// @dev Any additional condition to add token enumeration when overridden.
  function _additionalConditionAddTokenToOwnerEnumeration(address, uint256) internal virtual returns (bool) {
    return true;
  }

  /// @dev Hook that is called after any token transfer. This includes minting
  /// and burning.
  function _afterTokenTransfer(
    address,
    address from,
    address to,
    uint256[] memory ids,
    uint256[] memory amounts,
    bytes memory
  ) internal virtual override {
    for (uint256 i; i < ids.length; ) {
      if (amounts[i] != 0) _removeTokenEnumeration(from, to, ids[i], amounts[i]);

      unchecked {
        ++i;
      }
    }
  }

  /// @dev Remove token enumeration list if necessary.
  function _removeTokenEnumeration(address from, address to, uint256 id, uint256 amount) internal {
    if (to == address(0)) {
      _idTotalSupply[id] -= amount;
      if (_idTotalSupply[id] == 0 && _additionalConditionRemoveTokenFromAllTokensEnumeration(id))
        _removeTokenFromAllTokensEnumeration(id);
    }

    if (from != address(0) && from != to) {
      if (balanceOf(from, id) == 0 && _additionalConditionRemoveTokenFromOwnerEnumeration(from, id))
        _removeTokenFromOwnerEnumeration(from, id);
    }
  }

  /// @dev Any additional condition to remove token enumeration when overridden.
  function _additionalConditionRemoveTokenFromAllTokensEnumeration(uint256) internal virtual returns (bool) {
    return true;
  }

  /// @dev Any additional condition to remove token enumeration when overridden.
  function _additionalConditionRemoveTokenFromOwnerEnumeration(address, uint256) internal virtual returns (bool) {
    return true;
  }

  /// @dev Private function to add a token to this extension's ownership-tracking data structures.
  /// @param to address representing the new owner of the given token ID
  /// @param tokenId uint256 ID of the token to be added to the tokens list of the given address
  function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
    _ownedTokensIndex[to][tokenId] = _ownedTokens[to].length;
    _ownedTokens[to].push(tokenId);
  }

  /// @dev Private function to add a token to this extension's token tracking data structures.
  /// @param tokenId uint256 ID of the token to be added to the tokens list
  function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
    _allTokensIndex[tokenId] = _allTokens.length;
    _allTokens.push(tokenId);
  }

  /// @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
  /// while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
  /// gas optimizations e.g. when performing a transfer operation (avoiding double writes).
  /// This has O(1) time complexity, but alters the order of the _ownedTokens array.
  /// @param from address representing the previous owner of the given token ID
  /// @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
  function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
    uint256 lastTokenIndex = _ownedTokens[from].length - 1;
    uint256 tokenIndex = _ownedTokensIndex[from][tokenId];

    if (tokenIndex != lastTokenIndex) {
      uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

      _ownedTokens[from][tokenIndex] = lastTokenId;
      _ownedTokensIndex[from][lastTokenId] = tokenIndex;
    }

    delete _ownedTokensIndex[from][tokenId];
    _ownedTokens[from].pop();
  }

  /// @dev Private function to remove a token from this extension's token tracking data structures.
  /// This has O(1) time complexity, but alters the order of the _allTokens array.
  /// @param tokenId uint256 ID of the token to be removed from the tokens list
  function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
    uint256 lastTokenIndex = _allTokens.length - 1;
    uint256 tokenIndex = _allTokensIndex[tokenId];

    if (tokenIndex != lastTokenIndex) {
      uint256 lastTokenId = _allTokens[lastTokenIndex];

      _allTokens[tokenIndex] = lastTokenId;
      _allTokensIndex[lastTokenId] = tokenIndex;
    }

    delete _allTokensIndex[tokenId];
    _allTokens.pop();
  }
}