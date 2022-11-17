// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;

import {IERC20} from '../../dependencies/openzeppelin/contracts/IERC20.sol';

/**
 * @title IFlashLoanRecipient interface
 * @notice Interface for the IFlashLoanRecipient.
 * @author Sturdy
 * @dev implement this interface to develop a flashloan-compatible IFlashLoanRecipient contract
 **/
interface IFlashLoanRecipient {
  /**
   * @dev When `flashLoan` is called on the Vault, it invokes the `receiveFlashLoan` hook on the recipient.
   *
   * At the time of the call, the Vault will have transferred `amounts` for `tokens` to the recipient. Before this
   * call returns, the recipient must have transferred `amounts` plus `feeAmounts` for each token back to the
   * Vault, or else the entire flash loan will revert.
   *
   * `userData` is the same value passed in the `IVault.flashLoan` call.
   */
  function receiveFlashLoan(
    IERC20[] memory tokens,
    uint256[] memory amounts,
    uint256[] memory feeAmounts,
    bytes memory userData
  ) external;
}