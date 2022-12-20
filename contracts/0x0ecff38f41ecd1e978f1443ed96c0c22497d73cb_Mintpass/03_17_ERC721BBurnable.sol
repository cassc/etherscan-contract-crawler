// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../ERC721B.sol";
import "@openzeppelin/contracts/utils/Context.sol";

/**
 * @title ERC721B Burnable Token
 * @dev ERC721B Token that can be irreversibly burned (destroyed).
 */
abstract contract ERC721BBurnable is Context, ERC721B {

  // ============ Storage ============

  //mapping of token id to burned?
  mapping(uint256 => bool) private _burned;
  //count of how many burned
  uint256 private _totalBurned;

  // ============ Read Methods ============

  /**
   * @dev See {IERC721-ownerOf}.
   */
  function ownerOf(uint256 tokenId) 
    public view virtual override returns(address) 
  {
    if (_burned[tokenId]) revert NonExistentToken();
    return super.ownerOf(tokenId);
  }

  /**
   * @dev Shows the overall amount of tokens generated in the contract
   */
  function totalSupply() public virtual view override returns(uint256) {
    return super.totalSupply() - _totalBurned;
  }

  // ============ Write Methods ============

  /**
   * @dev Burns `tokenId`. See {ERC721B-_burn}.
   *
   * Requirements:
   *
   * - The caller must own `tokenId` or be an approved operator.
   */
  function burn(uint256 tokenId) public virtual {
    address owner = ERC721B.ownerOf(tokenId);
    if (!_isApprovedOrOwner(_msgSender(), tokenId, owner)) 
      revert InvalidCall();

    _beforeTokenTransfers(owner, address(0), tokenId, 1);
    
    // Clear approvals
    _approve(address(0), tokenId, owner);

    unchecked {
      //this is the situation when _owners are normalized
      _balances[owner] -= 1;
      _burned[tokenId] = true;
      _owners[tokenId] = address(0);
      _totalBurned++;

      //this is the situation when _owners are not normalized
      uint256 nextTokenId = tokenId + 1;
      if (nextTokenId <= totalSupply() && _owners[nextTokenId] == address(0)) {
        _owners[nextTokenId] = owner;
      }
    }

    _afterTokenTransfers(owner, address(0), tokenId, 1);

    emit Transfer(owner, address(0), tokenId);
  }

  // ============ Internal Methods ============

  /**
   * @dev Returns whether `tokenId` exists.
   *
   * Tokens can be managed by their owner or approved accounts via 
   * {approve} or {setApprovalForAll}.
   *
   * Tokens start existing when they are minted (`_mint`),
   * and stop existing when they are burned (`_burn`).
   */
  function _exists(uint256 tokenId) 
    internal view virtual override returns(bool) 
  {
    return !_burned[tokenId] && super._exists(tokenId);
  }
}