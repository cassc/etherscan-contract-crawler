// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;
import "./BEPContext.sol";

abstract contract BEPOwnable is BEPContext {
  address private _owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  
  constructor() {
    address msgSender = _msgSender();
    _owner = msgSender;
    emit OwnershipTransferred(address(0), msgSender);
  }


  function owner() public view returns (address) {
    return _owner;
  }

 
  modifier onlyOwner() {
    require(isOwner(), "Ownable: caller is not the owner");
    _;
  }

  
  function isOwner() public view returns (bool) {
    return _msgSender() == _owner;
  }


  function renounceOwnership() public onlyOwner {
    emit OwnershipTransferred(_owner, address(0));
    _owner = address(0);
  }

 
  function transferOwner(address newOwner) public onlyOwner {
    _transferOwnership(newOwner);
  }

 
  function _transferOwnership(address newOwner) internal {
    require(newOwner != address(0), "Ownable: new owner is the zero address");
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}