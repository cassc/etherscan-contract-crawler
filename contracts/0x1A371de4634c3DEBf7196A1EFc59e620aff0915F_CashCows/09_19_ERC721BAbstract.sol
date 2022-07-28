// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "erc721b/contracts/ERC721B.sol";

/**
 * @dev Packages all the specific ERC721B features needed including
 * contract URI, burnable
 */
abstract contract ERC721BAbstract is ERC721B { 
  // ============ Constants ============

  //contract URI
  string private _CONTRACT_URI;

  // ============ Storage ============

  //mapping of token id to who burned?
  mapping(uint256 => address) public burned;
  //count of how many burned
  uint256 private _totalBurned;
  
  // ============ Read Methods ============

  /**
   * @dev Returns the contract URI.
   */
  function contractURI() external view returns(string memory) {
    return _CONTRACT_URI;
  }

  /**
   * @dev Adds a provision for burnt tokens.
   */
  function ownerOf(
    uint256 tokenId
  ) public view override returns(address) {
    //error if burned
    if (burned[tokenId] != address(0)) revert NonExistentToken();
    return super.ownerOf(tokenId);
  }

  /**
   * @dev Returns all the owner's tokens. This is an incredibly 
   * ineffecient method and should not be used by other contracts.
   * It's recommended to call this on your dApp then call `ownsAll`
   * from your other contract instead.
   */
  function ownerTokens(
    address owner
  ) external view returns(uint256[] memory) {
    //get the balance
    uint256 balance = balanceOf(owner);
    //if no balance
    if (balance == 0) {
      //return empty array
      return new uint256[](0);
    }
    //this is how we can fix the array size
    uint256[] memory tokenIds = new uint256[](balance);
    //next get the total supply
    uint256 supply = totalSupply();
    //next declare the array index
    uint256 index;
    //loop through the supply
    for (uint256 i = 1; i <= supply; i++) {
      //if we found a token owner ows
      if (owner == ownerOf(i)) {
        //add it to the token ids
        tokenIds[index++] = i;
        //if the index is equal to the balance
        if (index == balance) {
          //break out to save time
          break;
        }
      }
    }
    //finally return the token ids
    return tokenIds;
  }

  /**
   * @dev Returns true if `owner` owns all the `tokenIds`
   */
  function ownsAll(
    address owner, 
    uint256[] memory tokenIds
  ) external view returns(bool) {
    for (uint256 i = 0; i < tokenIds.length; i++) {
      if (owner != ownerOf(tokenIds[i])) {
        return false;
      }
    }

    return true;
  }

  /**
   * @dev Shows the overall amount of tokens generated in the contract
   */
  function totalSupply() public view override returns(uint256) {
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
  function burn(uint256 tokenId) external {
    address owner = ERC721B.ownerOf(tokenId);
    if (!_isApprovedOrOwner(_msgSender(), tokenId, owner)) 
      revert InvalidCall();

    _beforeTokenTransfers(owner, address(0), tokenId, 1);
    
    // Clear approvals
    _approve(address(0), tokenId, owner);

    unchecked {
      //this is the situation when _owners are not normalized
      //get the next token id
      uint256 nextTokenId = tokenId + 1;
      //if token exists and yet it is address 0
      if (_exists(nextTokenId) && _owners[nextTokenId] == address(0)) {
        _owners[nextTokenId] = owner;
      }

      //this is the situation when _owners are normalized
      burned[tokenId] = owner;
      _balances[owner] -= 1;
      _owners[tokenId] = address(0);
      _totalBurned++;
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
   *
   * The parent defines `_exists` as greater than 0 and less than 
   * the last token id
   */
  function _exists(
    uint256 tokenId
  ) internal view virtual override returns(bool) {
    return burned[tokenId] == address(0) && super._exists(tokenId);
  }

  /**
   * @dev Sets the contract URI
   */
  function _setURI(string memory uri) internal {
    _CONTRACT_URI = uri;
  }
}