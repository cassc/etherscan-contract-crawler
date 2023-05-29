// SPDX-License-Identifier: MIT
// 2022 Infinity Keys Team
pragma solidity ^0.8.0;

/************************************************************
* @title: Authorized                                        *
* @notice: Allow list of authorized addresses for           *
* certain function calls.  Extension of Ownable             *
************************************************************/

import "@openzeppelin/contracts/access/Ownable.sol";

contract Authorized is Ownable{
  /**
  @dev Set of addresses authorized for certain function calls.
  */
  mapping(address => bool) internal _authorized;

  constructor(){
    _authorized[owner()] = true;
  }

  /**
  @dev Modifier to enforce authorization rules.
  */
  modifier onlyAuthorized {
    require(_authorized[msg.sender], "onlyAuthorized: Invalid address" );
    _;
  }

  /**
  @dev Returns whether or not an address is authorized for function calls.
  */
  function isAuthorized( address addr ) public view returns ( bool ){
    return _authorized[addr];
  }

  /**
  @dev Adds an authorized account (onlyOwner).
  */
  function addAuthorizedAccount( address addr) external onlyOwner{
    require( !isAuthorized(addr), "addAuthorizedAccount: Account is already authorized." );
    _authorized[addr] = true;
  }

  /**
  @dev Removes an authorized account (onlyOwner)
  */
  function removeAuthorizedAccount( address addr) external onlyOwner{
    require( isAuthorized(addr), "removeAuthorizedAccount: Account is not authorized." );
    _authorized[addr] = false;
  }

  /**
  @dev Transfers ownership to new address (onlyOwner)
  */
  function transferOwnership(address newOwner) public virtual override onlyOwner {
    _authorized[newOwner] = true;
    super.transferOwnership( newOwner );
  }
}