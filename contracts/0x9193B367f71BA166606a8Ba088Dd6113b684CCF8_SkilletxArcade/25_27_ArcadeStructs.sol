//SPDX-License-Identifier: Skillet-Group
pragma solidity ^0.8.0;

import "../interfaces/IOriginationController.sol";

struct BaseLoanTerms {
  uint32 durationSecs;
  uint32 deadline;
  uint24 numInstallments;
  uint160 interestRate;
  uint256 principal;
  address payableCurrency;
}

struct ArcadeLoan {
  BaseLoanTerms loanTerms;
  IOriginationController.Predicate itemPredicate;
  IOriginationController.Signature sig;
  uint160 nonce;
  address lenderAddress;
}