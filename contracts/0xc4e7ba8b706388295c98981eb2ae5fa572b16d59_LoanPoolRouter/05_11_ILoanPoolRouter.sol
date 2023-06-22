// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ILoanPool.sol";

interface ILoanPoolRouter {
  function fundLoanPool(
    ILoanPool loanPool,
    uint256 amount,
    address recipient
  ) external;

  function domainSeparator() external view returns (bytes32 separator);

  function fundLoanPoolWithPermit(
    address lender,
    ILoanPool loanPool,
    uint256 amount,
    address recipient,
    uint256 deadline,
    uint256 salt,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external;

  function cancelPermit() external;

  function permitNonce(address lender) external view returns (uint256 nonce);

  event LoanPoolFunded(
    address indexed loanPool,
    address indexed lender,
    address indexed recipient,
    uint256 amount
  );

  error PermitUsed();
  error PermitExpired();
  error InvalidSignature();
}