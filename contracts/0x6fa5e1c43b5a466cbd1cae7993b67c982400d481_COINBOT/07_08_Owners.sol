// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import { Context } from './Context.sol';

abstract contract Ownable is Context {
  address private _owner;

  constructor() {
    _transferOwnership(_msgSender());
  }

  function owner() public view virtual returns (address) {
    return _owner;
  }

  modifier onlyOwner() {
    require(owner() == _msgSender(), 'Ownable: caller is not the owner');
    _;
  }

  function renounceOwnership() public virtual onlyOwner {
    _transferOwnership(address(0));
  }

  function transferOwnership(address newOwner) public virtual onlyOwner {
    require(newOwner != address(0), 'Ownable: new owner is the zero address');
    _transferOwnership(newOwner);
  }

  function _transferOwnership(address newOwner) internal virtual {
    _owner = newOwner;
  }
}