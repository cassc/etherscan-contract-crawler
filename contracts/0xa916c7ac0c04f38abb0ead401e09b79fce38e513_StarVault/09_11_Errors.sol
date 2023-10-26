// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

abstract contract Errors {
  error AlreadyInitialized();
  error EthTransferFailed();
  error IncorrectEthValue();
  error ZeroAmountOut();
  error InsufficientOutputAmount();
  error DeadlineExpired();
}