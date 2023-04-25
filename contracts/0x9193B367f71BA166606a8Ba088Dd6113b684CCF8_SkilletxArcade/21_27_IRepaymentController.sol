//SPDX-License-Identifier: Skillet-Group
pragma solidity ^0.8.0;

/**
 * Skillet <> Arcade
 * Repayment Controller Interface
 * https://etherscan.io/address/0xb39dAB85FA05C381767FF992cCDE4c94619993d4#code
 */
interface IRepaymentController {
  function repay(uint256 loanId) external;
}