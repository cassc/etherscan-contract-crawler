// SPDX-License-Identifier: MIT
/**
  ∩~~~~∩ 
  ξ ･×･ ξ 
  ξ　~　ξ 
  ξ　　 ξ 
  ξ　　 “~～~～〇 
  ξ　　　　　　 ξ 
  ξ ξ ξ~～~ξ ξ ξ 
　 ξ_ξξ_ξ　ξ_ξξ_ξ
Alpaca Fin Corporation
*/
pragma solidity 0.8.12;

abstract contract Ownable {
  error Ownable_NotOwner();
  error Ownable_NewOwnerZeroAddress();

  address public owner;

  event LogOwnershipTransferred(address indexed from, address indexed to);

  modifier onlyOwner() {
    if (msg.sender != owner) revert Ownable_NotOwner();
    _;
  }

  function _transferOwnership(address _newOwner) internal virtual {
    address _prevOwner = owner;
    owner = _newOwner;
    emit LogOwnershipTransferred(_prevOwner, _newOwner);
  }

  function transferOwnership(address _newOwner) public virtual onlyOwner {
    if (_newOwner == address(0)) revert Ownable_NewOwnerZeroAddress();
    _transferOwnership(_newOwner);
  }
}
