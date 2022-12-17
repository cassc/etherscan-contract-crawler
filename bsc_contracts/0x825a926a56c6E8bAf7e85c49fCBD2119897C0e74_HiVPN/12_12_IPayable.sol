// SPDX-License-Identifier: PROTECTED
// [email protected]
pragma solidity ^0.8.0;

interface IPayable {
  event NewPayment(
    address indexed user,
    address indexed referrer,
    uint256 planId,
    uint256 value
  );

  struct Payment {
    address user;
    uint256 time;
    address token;
    uint256 value;
    uint256 planId;
    uint256 amount;
  }

  function paymentDetails(
    uint256 id
  ) external view returns (address user, uint value, uint planId);

  function paymentDetailByIndex(uint256 index) external view returns (Payment memory);

  function allPayments() external view returns (uint256[] memory);

  function paymentCount() external view returns (uint256);
}