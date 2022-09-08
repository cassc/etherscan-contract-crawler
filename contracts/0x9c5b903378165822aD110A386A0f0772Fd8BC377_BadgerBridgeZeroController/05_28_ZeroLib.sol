// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0 <0.8.0;

/**
@title helper functions for the Zero contract suite
@author raymondpulver
*/
library ZeroLib {
  enum LoanStatusCode {
    UNINITIALIZED,
    UNPAID,
    PAID
  }
  struct LoanParams {
    address to;
    address asset;
    uint256 amount;
    uint256 nonce;
    address module;
    bytes data;
  }
  struct MetaParams {
    address from;
    uint256 nonce;
    bytes data;
    address module;
    address asset;
  }
  struct LoanStatus {
    address underwriter;
    LoanStatusCode status;
  }
  struct BalanceSheet {
    uint128 loaned;
    uint128 required;
    uint256 repaid;
  }
}