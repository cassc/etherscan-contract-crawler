//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/finance/VestingWallet.sol";

contract BottoVesting {
    VestingWallet public epoch1VestingWallet;
    VestingWallet public epoch2VestingWallet;

    constructor(
        address beneficiary,
        uint64 cliffDuration,
        uint64 vestingDuration
    ) {
        uint64 startTimestamp = uint64(block.timestamp) + cliffDuration;

        epoch1VestingWallet = new VestingWallet(beneficiary, startTimestamp, 0);

        epoch2VestingWallet = new VestingWallet(
            beneficiary,
            startTimestamp,
            vestingDuration
        );
    }
}