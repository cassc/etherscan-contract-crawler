// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

abstract contract ICreditDesk {
  uint256 public totalWritedowns;
  uint256 public totalLoansOutstanding;

  function setUnderwriterGovernanceLimit(address underwriterAddress, uint256 limit) external virtual;

  function drawdown(address creditLineAddress, uint256 amount) external virtual;

  function pay(address creditLineAddress, uint256 amount) external virtual;

  function assessCreditLine(address creditLineAddress) external virtual;

  function applyPayment(address creditLineAddress, uint256 amount) external virtual;

  function getNextPaymentAmount(address creditLineAddress, uint256 asOfBLock) external view virtual returns (uint256);
}