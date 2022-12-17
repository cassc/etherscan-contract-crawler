// SPDX-License-Identifier: PROTECTED
// [email protected]
pragma solidity ^0.8.0;

import "./Math.sol";
import "./Secured.sol";
import "./IPayable.sol";

abstract contract Payable is IPayable, Secured {
  mapping(uint256 => Payment) public payments;
  uint256[] public paymentList;

  // View functions ------------------------------------------------------------
  function paymentDetails(
    uint256 id
  ) external view override returns (address user, uint amount, uint planId) {
    Payment memory details = payments[id];
    return (details.user, details.value, details.planId);
  }

  function paymentDetailByIndex(
    uint256 index
  ) public view override returns (Payment memory) {
    return payments[paymentList[index]];
  }

  function paymentCount() external view override returns (uint256) {
    return paymentList.length;
  }

  function allPayments() external view override returns (uint256[] memory) {
    return paymentList;
  }

  // Modify functions ------------------------------------------------------------
  function changePaymentDetail(uint256 id, Payment memory detail) external onlyAdmin {
    payments[id] = detail;
  }
}