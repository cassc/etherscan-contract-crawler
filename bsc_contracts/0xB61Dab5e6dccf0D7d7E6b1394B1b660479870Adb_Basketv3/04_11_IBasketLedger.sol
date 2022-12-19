// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9 <0.9.0;

interface IBasketLedger {
  function xlpSupply(address _vault, address _account) external returns(uint256);
  function deposit(address _account, address _vault, uint256 _amount) external;
  function withdraw(address _account, address _vault, uint256 _amount) external returns(uint256);
}