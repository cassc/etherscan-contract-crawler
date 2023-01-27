// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * See https://github.com/ethereum/EIPs/issues/179
 */
abstract contract ERC20Basic {
  function totalSupply() public virtual view returns (uint256);
  function balanceOf(address _who) public virtual view returns (uint256);
  function transfer(address _to, uint256 _value) public virtual returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}
