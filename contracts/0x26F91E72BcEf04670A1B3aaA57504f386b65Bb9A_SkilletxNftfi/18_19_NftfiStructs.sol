// SPDX-License-Identifier: Skillet Group
pragma solidity ^0.8.0;

import "../interfaces/ILoanOriginator.sol";

struct NftfiLoan {
  ILoanOriginator.Offer offer;
  ILoanOriginator.Signature sig;
  ILoanOriginator.BorrowerSettings borrowerSettings;
}