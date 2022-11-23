// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.4;

import "@openzeppelin/contracts/finance/VestingWallet.sol";

contract Vesting is VestingWallet {
    error InvalidStartDate();
    error InvalidDuration();

    constructor(
        address beneficiaryAddress,
        uint64 startTimestamp,
        uint64 durationSeconds
    ) VestingWallet(beneficiaryAddress, startTimestamp, durationSeconds) {

      if(startTimestamp < block.timestamp) revert InvalidStartDate();
      if(durationSeconds == 0) revert InvalidDuration();
    }
}