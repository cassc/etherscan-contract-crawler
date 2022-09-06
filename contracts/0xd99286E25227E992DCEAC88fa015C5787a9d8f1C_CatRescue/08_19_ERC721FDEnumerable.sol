// SPDX-License-Identifier: MIT

// ERC721FDEnumerable extends ERC721FD to implement ERC721Enumerable.

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import '@openzeppelin/contracts/utils/Counters.sol';
import '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol';
import './ERC721FD.sol';

abstract contract ERC721FDEnumerable is ERC721FD, IERC721Enumerable {
  uint256 private immutable _nonDevMintInventory;
  mapping(address => mapping(uint256 => uint256)) private _ownedTokens;
  mapping(uint256 => uint256) private _ownedTokensIndex;

  constructor(
    string memory name_,
    string memory symbol_,
    uint256 devMintInventory_,
    uint256 nonDevMintInventory_
  ) ERC721FD(name_, symbol_, devMintInventory_) {
    _nonDevMintInventory = nonDevMintInventory_;
  }

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

  function tokenOfOwnerByIndex(address owner, uint256 index)
    public
    view
    virtual
    override
    returns (uint256)
  {
    require(
      index < balanceOf(owner),
      'ERC721Enumerable: owner index out of bounds'
    );

    if (owner == devMintAddress_()) {
      uint256 devMintAddressHoldCount = devMintInventory() -
        devMintReleasedCount_();
      if (index < devMintAddressHoldCount) {
        uint256 currIndex = 0;
        for (uint256 tokenId = 1; tokenId <= devMintInventory(); tokenId++) {
          if (_underlyingOwnerOf(tokenId) == address(0)) {
            if (currIndex == index) {
              return tokenId;
            } else {
              currIndex++;
            }
          }
        }
        require(
          false,
          'ERC721FDEnumerable: failed to resolve devMinted tokenId'
        );
      }
    }
    return _ownedTokens[owner][index];
  }

  function totalSupply() public view virtual override returns (uint256) {
    return devMintInventory() + _nonDevMintInventory;
  }

  function tokenByIndex(uint256 index)
    public
    view
    virtual
    override
    returns (uint256)
  {
    require(
      index < totalSupply(),
      'ERC721Enumerable: global index out of bounds'
    );
    return index + 1;
  }

  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 tokenId
  ) internal virtual override {
    // super._beforeTokenTransfer(from, to, tokenId);

    if (from != address(0) && from != to) {
      _removeTokenFromOwnerEnumeration(from, tokenId);
    }
    if (to == address(0)) {
      // nothing to do because we don't implement burn
      // _removeTokenFromAllTokensEnumeration(tokenId);
    } else if (to != from) {
      _addTokenToOwnerEnumeration(to, tokenId);
    }
  }

  function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
    uint256 length = balanceOf(to);
    if (to == devMintAddress_() && tokenId <= devMintInventory()) {
      // When devMinted token are transferred back,
      // last indexed token of devMintAddress should be move to next index to free stot for the token tranferred.
      if (length > devMintInventory() - devMintReleasedCount_()) {
        uint256 lastTokenId = _ownedTokens[to][length - 1];
        _ownedTokens[to][length] = lastTokenId;
        _ownedTokensIndex[lastTokenId] = length;
      }
    } else {
      _ownedTokens[to][length] = tokenId;
      _ownedTokensIndex[tokenId] = length;
    }
  }

  function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId)
    private
  {
    if (from != devMintAddress_() || tokenId > devMintInventory()) {
      // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
      // then delete the last slot (swap and pop).

      uint256 lastTokenIndex = balanceOf(from) - 1;
      uint256 tokenIndex = _ownedTokensIndex[tokenId];

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
}