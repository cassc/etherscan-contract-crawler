// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "../protocol/core/BaseUpgradeablePausable.sol";
import "../protocol/core/CreditLine.sol";

contract TestCreditLine is CreditLine {
  function setPaymentPeriodInDays(uint256 _paymentPeriodInDays) public onlyAdmin {
    paymentPeriodInDays = _paymentPeriodInDays;
  }

  function setInterestApr(uint256 _interestApr) public onlyAdmin {
    interestApr = _interestApr;
  }
}