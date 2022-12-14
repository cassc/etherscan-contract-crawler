// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9 <0.9.0;

interface ILiquidCryptoBridge_v1 {
  struct SwapVoucher {
    address account;
    uint256 inChain;
    uint256 inAmount;
    uint256 outChain;
    uint256 outAmount;
  }

  function depositForUser(uint256 fee) external payable;
  function withdrawForUser(address account, bool isContract, uint256 outAmount, uint256 fee) external;
  function refundFaildVoucher(uint256 index, uint256 amount, uint256 fee) external;
}