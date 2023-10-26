// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;


interface IERC20 {
  event Transfer(address indexed _from, address indexed _to, uint256 _value);
  event Approval(address indexed _owner, address indexed _spender, uint256 _value);

  function totalSupply() external view returns (uint256);
  function balanceOf(address _account) external view returns (uint256);
  function transfer(address _to, uint256 _amount) external returns (bool);
  function allowance(address _owner, address _spender) external view returns (uint256);
  function approve(address _spender, uint256 _amount) external returns (bool);
  function transferFrom(address _from, address _to, uint256 _amount) external returns (bool);
}