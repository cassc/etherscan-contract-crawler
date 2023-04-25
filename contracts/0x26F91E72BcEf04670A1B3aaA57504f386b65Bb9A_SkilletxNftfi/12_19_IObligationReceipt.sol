// SPDX-License-Identifier: Skillet Group
pragma solidity ^0.8.0;

/**
 * NFTFi Obligation Receipt
 * https://etherscan.io/address/0xe73ECe5988FfF33a012CEA8BB6Fd5B27679fC481
 */
interface IObligationReceipt {
  struct Loan {
    address loanCoordinator;
    uint256 loanId;
  }

  function loans(uint256 obligationId) external view returns (Loan memory);
}