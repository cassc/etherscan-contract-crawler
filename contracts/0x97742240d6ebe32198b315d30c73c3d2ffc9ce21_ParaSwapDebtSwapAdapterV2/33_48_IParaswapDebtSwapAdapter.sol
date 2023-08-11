// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;
import {ICreditDelegationToken} from './ICreditDelegationToken.sol';

interface IParaswapDebtSwapAdapter {
  struct FlashParams {
    address debtAsset;
    uint256 debtRepayAmount;
    uint256 debtRateMode;
    bytes paraswapData;
    uint256 offset;
    address user;
  }

  struct DebtSwapParams {
    address debtAsset;
    uint256 debtRepayAmount;
    uint256 debtRateMode;
    address newDebtAsset;
    uint256 maxNewDebtAmount;
    uint256 offset;
    bytes paraswapData;
  }

  struct CreditDelegationInput {
    ICreditDelegationToken debtToken;
    uint256 value;
    uint256 deadline;
    uint8 v;
    bytes32 r;
    bytes32 s;
  }

  /**
   * @dev swaps debt from one asset to another
   * @param debtSwapParams struct describing the debt swap
   * @param creditDelegationPermit optional permit for credit delegation
   */
  function swapDebt(
    DebtSwapParams memory debtSwapParams,
    CreditDelegationInput memory creditDelegationPermit
  ) external;
}