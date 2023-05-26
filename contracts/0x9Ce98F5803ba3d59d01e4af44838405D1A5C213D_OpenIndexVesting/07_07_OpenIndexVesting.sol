// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/finance/VestingWallet.sol";

contract OpenIndexVesting is VestingWallet {
  constructor(address beneficiaryAddress, uint64 startTimestamp, uint64 durationSeconds)
    VestingWallet(beneficiaryAddress, startTimestamp, durationSeconds) {
  }
}