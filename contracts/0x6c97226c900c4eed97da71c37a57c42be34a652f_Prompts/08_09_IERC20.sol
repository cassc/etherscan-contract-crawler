pragma solidity ^0.8.13;

interface IERC20 {
  function approve(address spender, uint amount) external returns (bool);
  function balanceOf(address account) external returns (uint256);
  function transfer(address to, uint256 value) external returns (bool);
  function totalSupply() external returns (uint256);
}