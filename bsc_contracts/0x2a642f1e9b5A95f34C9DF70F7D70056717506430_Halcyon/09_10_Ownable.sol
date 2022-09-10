// SPDX-License-Identifier: MIT

pragma solidity =0.8.16;

import "../utils/Context.sol";

abstract contract Ownable is Context
{
  address private _owner;
  
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
  
  constructor()
  {
    _owner = _msgSender();
    
    emit OwnershipTransferred(address(0), _owner);
  }
  
  function owner() public view virtual returns (address)
  {
    return _owner;
  }
  
  modifier onlyOwner()
  {
    require(_owner == _msgSender(), "Not the owner.");
    _;
  }
}