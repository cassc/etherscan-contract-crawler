/**
 *Submitted for verification at Etherscan.io on 2023-06-05
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;
contract MemePanda{
  string public name = "MemePanda";
  string public symbol = "MPD";
  string public standard = "MemePanda v1.0";
  uint256 public totalSupply;
  uint8 public decimals = 18;
  event Transfer(
    address indexed _from,
    address indexed _to,
    uint256 _value
    );

  event Approval(
    address indexed _owner,
    address indexed _spender,
    uint256 _value
    );

  mapping(address => uint256) public balanceOf;
  mapping(address => mapping(address => uint256)) public allowance;

  constructor(uint256 _initialSupply)  {
    totalSupply = _initialSupply * 10 ** uint256(decimals);
    balanceOf[msg.sender] = totalSupply;
  }


  function transfer(address _to, uint256 _value) public returns (bool success){
    require(balanceOf[msg.sender] >= _value,
      "Tokens transferred must be less or equal to account balance");
    balanceOf[msg.sender] -= _value;
    balanceOf[_to] += _value;
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

  function approve(address _spender, uint256 _value) public returns (bool success){
    allowance[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

  function transferFrom(address _from, address _to, uint256 _value) public returns (bool success){
    require(balanceOf[_from] >= _value,
       "Tokens transferred must be less or equal to account balance");
    require(allowance[_from][msg.sender] >= _value,
       "Tokens transferred must be less or equal to allowance");

    balanceOf[_from] -= _value;
    balanceOf[_to] += _value;

    allowance[_from][msg.sender] -= _value;

    emit Transfer(_from, _to, _value);

    return true;

  }

}