// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.6;


interface IERC20
{
  function balanceOf (address account) external view returns (uint256);


  function approve (address spender, uint256 amount) external returns (bool);


  function transfer (address to, uint256 amount) external returns (bool);

  function transferFrom (address from, address to, uint256 amount) external returns (bool);
}