// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Delegated is Ownable{
  mapping(address => bool) internal _delegates;

  modifier onlyContracts {
    require(_delegates[msg.sender], "Unauthorized delegate" );
    require(msg.sender.code.length > 0, "Non-contract delegate" );
    _;
  }

  modifier onlyDelegates {
    require(_delegates[msg.sender], "Unauthorized delegate" );
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