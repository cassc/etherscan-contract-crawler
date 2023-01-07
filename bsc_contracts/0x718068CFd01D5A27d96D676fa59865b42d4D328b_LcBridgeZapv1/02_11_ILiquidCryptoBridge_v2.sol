// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9 <0.9.0;

interface ILiquidCryptoBridge_v2 {
  function swap(address _to, address _refund, uint256 _outChainID) external payable returns(uint256);
  function redeem(uint256 _amount, address _to, uint256 _fee, bool wrapped) external returns(uint256);
  function refund(uint256 _index, uint256 _fee) external;
  
  function getAmountsIn(uint256 _amount) external view returns(uint256 coin);
  function getAmountsOut(uint256 _amount) external view returns(uint256 stableAmount);
}