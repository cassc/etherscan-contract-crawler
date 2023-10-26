// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { Context } from "../library/Context.sol";
import { IOwnableV2 } from "./IOwnableV2.sol";

/**
 * @title Ownable
 * 
 * parent for ownable contracts
 */
abstract contract OwnableV2 is IOwnableV2, Context {
  constructor(address owner_) {
    _owner_ = owner_;
    emit OwnershipTransferred(address(0), _owner());
  }

  address internal _owner_;

  function _owner() internal virtual view returns (address) {
    return _owner_;
  }

  function owner() external virtual override view returns (address) {
    return _owner();
  }

  modifier onlyOwner() {
    require(_owner() == _msgSender(), "Only the owner can execute this function");
    _;
  }

  function _transferOwnership(address newOwner_) internal virtual onlyOwner {
    // keep track of old owner for event
    address oldOwner = _owner();

    // set the new owner
    _owner_ = newOwner_;

    // emit event about ownership change
    emit OwnershipTransferred(oldOwner, _owner());
  }

  function transferOwnership(address newOwner_) external virtual override onlyOwner {
    _transferOwnership(newOwner_);
  }
}