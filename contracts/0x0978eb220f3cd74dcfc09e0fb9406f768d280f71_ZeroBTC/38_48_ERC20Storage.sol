// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.13;

contract ERC20Storage {
  uint256 internal _totalSupply;

  mapping(address => uint256) internal _balanceOf;

  mapping(address => mapping(address => uint256)) internal _allowance;
}