// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./IRoyaltySplitter.sol";

// ============ Interfaces ============

interface IERC20Mintable is IERC20 {
  function mint(address to, uint256 amount) external;
}

interface IERC721Burnable is IERC721 {
  function burn(uint256 tokenId) external;
}

// ============ Contract ============

contract CashCowsCulling is Ownable {
  // ============ Errors ============

  error InvalidCall();

  // ============ Storage ============

  //mapping of owner to balance
  mapping(address => uint256) private _balances;
  //mapping of owner to unclaimed amount
  mapping(address => uint256) private _unclaimed;
  //conversion from eth to token
  uint256 private _tokenConversion; 
  //erc20 mintable token
  IERC20Mintable private _token;
  //royalty splitter
  IRoyaltySplitter private _treasury;
  //erc721 burnable collection
  IERC721Burnable private _collection;

  // ============ Read Methods ============

  /**
   * @dev Returns burnt balance
   */
  function balanceOf(address owner) external view returns(uint256) {
    return _balances[owner];
  }

  /**
   * @dev Returns redeemable balance
   */
  function redeemable(address owner) public view returns(uint256) {
    return _unclaimed[owner] * _tokenConversion;
  }

  // ============ Write Methods ============

  /**
   * @dev Burns `tokenId`, records event
   */
  function burn(uint256 tokenId) external {
    //get owner
    address owner = _msgSender();
    //only the caller can burn their own token
    if (owner != _collection.ownerOf(tokenId)) revert InvalidCall();
    //set burnt balance
    _balances[owner]++; 
    //get releaseable
    _unclaimed[owner] += _treasury.releaseable(tokenId);
    //burn it... muahhahaha
    //this contract needs permission to burn
    _collection.burn(tokenId);
  }

  /**
   * @dev Redeems unclaimed
   */
  function redeem() external {
    //get owner
    address owner = _msgSender();
    //this contract needs permission to mint
    _token.mint(owner, redeemable(owner));
    _unclaimed[owner] = 0;
  }

  // ============ Admin Methods ============

  /**
   * @dev Sets the collection
   */
  function setCollection(IERC721Burnable collection) external onlyOwner {
    _collection = collection;
  }

  /**
   * @dev Set the token conversion
   */
  function setTokenConversion(uint256 conversion) external onlyOwner {
    _tokenConversion = conversion;
  }

  /**
   * @dev Set the token
   */
  function setToken(IERC20Mintable token) external onlyOwner {
    _token = token;
  }

  /**
   * @dev Sets the treasury
   */
  function setTreasury(IRoyaltySplitter treasury) external onlyOwner {
    _treasury = treasury;
  }
}