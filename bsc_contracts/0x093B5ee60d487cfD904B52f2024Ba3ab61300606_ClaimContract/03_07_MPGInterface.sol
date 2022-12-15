// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

interface MPGInterface{

  function isEarlyInvestor(address investor) external view returns(bool);
  function transfer(address recipient, uint256 amount) external returns (bool);
  function balanceOf(address account) external view returns (uint256);
}