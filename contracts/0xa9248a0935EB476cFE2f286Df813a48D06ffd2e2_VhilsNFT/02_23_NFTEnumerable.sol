// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import { BaseControl } from "./BaseControl.sol";
import { ERC721Royalty, ERC721, IERC721, IERC165 } from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Royalty.sol";
import { IERC721Enumerable } from "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import { ERC721Burnable } from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import { BitMaps } from "@openzeppelin/contracts/utils/structs/BitMaps.sol";

// LightLink 2022

abstract contract NFTEnumerable is BaseControl, IERC721Enumerable, ERC721Royalty, ERC721Burnable {
  using BitMaps for BitMaps.BitMap;

  // Mapping from owner to list of owned token IDs
  mapping(address => BitMaps.BitMap) internal _ownedTokens;

  // all token ids, used for enumeration
  BitMaps.BitMap internal _allTokens;
  uint256 internal totalCount;

  constructor() ERC721("Layers", "LAYERS") {
    _setDefaultRoyalty(msg.sender, 500);
  }

  function _burn(uint256 tokenId) internal virtual override(ERC721, ERC721Royalty) {
    super._burn(tokenId);
  }

  /** Admin */
  function setDefaultRoyalty(address _receiver, uint96 _feeNumerator) external onlyOwner {
    _setDefaultRoyalty(_receiver, _feeNumerator);
  }

  function setTokenRoyalty(
    uint16 _tokenId,
    address _receiver,
    uint96 _feeNumerator
  ) external onlyOwner {
    _setTokenRoyalty(_tokenId, _receiver, _feeNumerator);
  }

  /** View */
  function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721, ERC721Royalty) returns (bool) {
    return interfaceId == type(IERC721Enumerable).interfaceId || ERC721Royalty.supportsInterface(interfaceId);
  }

  function tokenByIndex(uint256 _index) public view virtual override returns (uint256) {
    require(_index < NFTEnumerable.totalSupply(), "ERC721Enumerable: global index out of bounds");
    uint16 tokenId;
    uint16 currentIdx;
    for (uint16 i = 0; i < 10000; i++) {
      if (!_allTokens.get(i)) continue;
      if (currentIdx == _index) {
        tokenId = i;
        break;
      }
      currentIdx++;
    }
    return tokenId;
  }

  function tokenOfOwnerByIndex(address _owner, uint256 _index) public view virtual override returns (uint256) {
    require(_index < ERC721.balanceOf(_owner), "ERC721Enumerable: owner index out of bounds");
    uint16 tokenId;
    uint16 currentIdx;
    for (uint16 i = 0; i < 10000; i++) {
      if (!_ownedTokens[_owner].get(i)) continue;
      if (currentIdx == _index) {
        tokenId = i;
        break;
      }
      currentIdx++;
    }
    return tokenId;
  }

  function totalSupply() public view virtual override returns (uint256) {
    return totalCount;
  }

  function _beforeTokenTransfer(
    address _from,
    address _to,
    uint256 _tokenId
  ) internal virtual override {
    super._beforeTokenTransfer(_from, _to, _tokenId);
    require(_from == address(0) || !tokenPaused, "Token paused");

    if (_from == address(0)) {
      _addTokenToAllTokensEnumeration(_tokenId);
    } else if (_from != _to) {
      _removeTokenFromOwnerEnumeration(_from, _tokenId);
    }
    if (_to == address(0)) {
      _removeTokenFromAllTokensEnumeration(_tokenId);
    } else if (_to != _from) {
      _addTokenToOwnerEnumeration(_to, _tokenId);
    }
  }

  function _addTokenToOwnerEnumeration(address _to, uint256 _tokenId) private {
    _ownedTokens[_to].set(_tokenId);
  }

  function _addTokenToAllTokensEnumeration(uint256 _tokenId) private {
    _allTokens.set(_tokenId);
    totalCount++;
  }

  function _removeTokenFromOwnerEnumeration(address _from, uint256 _tokenId) private {
    _ownedTokens[_from].unset(_tokenId);
  }

  function _removeTokenFromAllTokensEnumeration(uint256 _tokenId) private {
    _allTokens.unset(_tokenId);
    if (totalCount > 0) totalCount--;
  }
}