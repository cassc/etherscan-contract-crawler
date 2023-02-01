// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.6;


interface IGlove
{
  function balanceOf (address account) external view returns (uint256);


  function creditOf (address account) external view returns (uint256);

  function creditlessOf (address account) external view returns (uint256);


  function transfer (address to, uint256 amount) external returns (bool);

  function transferFrom (address from, address to, uint256 amount) external returns (bool);

  function transferCreditless (address to, uint256 amount) external returns (bool);


  function mint (address account, uint256 amount) external;

  function mintCreditless (address account, uint256 amount) external;

  function creditize (address account, uint256 credits) external returns (bool);


  function burn (address account, uint256 amount) external;

  function decreditize (address account, uint256 credits) external returns (bool);
}