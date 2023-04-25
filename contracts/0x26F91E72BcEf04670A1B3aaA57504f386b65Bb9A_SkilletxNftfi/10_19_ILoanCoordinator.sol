// SPDX-License-Identifier: Skillet Group
pragma solidity ^0.8.0;

/**
 * Skillet <> NFTfi
 * NFTFi Loan Coordinator
 * https://etherscan.io/address/0x0C90C8B4aa8549656851964d5fB787F0e4F54082#code
 */
interface ILoanCoordinator {
  function totalNumLoans() external view returns (uint32);
}