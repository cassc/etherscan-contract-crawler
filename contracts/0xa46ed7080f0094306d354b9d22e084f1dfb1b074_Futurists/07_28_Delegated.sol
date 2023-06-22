// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";

contract Delegated is Ownable{
  error NotEOA();
  error NotAContract();
  error UnauthorizedDelegate();

  mapping(address => bool) internal _delegates;

  modifier onlyContracts {
    if(!_delegates[msg.sender]) revert UnauthorizedDelegate();
    if(!Address.isContract(msg.sender)) revert NotAContract();

    _;
  }

  modifier onlyDelegates {
    if(!_delegates[msg.sender]) revert UnauthorizedDelegate();

    _;
  }

  modifier onlyEOA {
    if(!_delegates[msg.sender]) revert UnauthorizedDelegate();
    if(Address.isContract(msg.sender)) revert NotEOA();

    _;
  }

  constructor()
    Ownable(){
    setDelegate(owner(), true);
  }

  //onlyOwner
  function isDelegate(address addr) external view onlyOwner returns(bool) {
    return _delegates[addr];
  }

  function setDelegate(address addr, bool isDelegate_) public onlyOwner {
    _delegates[addr] = isDelegate_;
  }

  function transferOwnership(address newOwner) public virtual override onlyOwner {
    setDelegate(newOwner, true);
    super.transferOwnership(newOwner);
  }
}