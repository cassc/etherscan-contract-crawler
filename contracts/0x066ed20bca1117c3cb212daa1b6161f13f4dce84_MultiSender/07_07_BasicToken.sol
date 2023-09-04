// SPDX-License-Identifier: MIT
pragma solidity ^0.4.0;

import "./ERC20.sol";
import "./SafeMath.sol";

contract BasicToken is ERC20Basic {

  using SafeMath for uint;

  mapping(address => uint) balances;

  function transfer(address _to, uint _value) public{
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
  }

  function balanceOf(address _owner) public constant returns (uint balance) {
    return balances[_owner];
  }
}