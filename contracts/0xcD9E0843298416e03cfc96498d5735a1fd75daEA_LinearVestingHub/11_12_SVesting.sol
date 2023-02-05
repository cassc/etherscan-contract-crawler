// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

struct Vesting {
    uint8 id;
    address receiver;
    uint256 tokenBalance; // remaining token balance
    uint256 withdrawnTokens; //
    uint256 startTime; // vesting start time.
    uint256 cliffDuration; // lockup time.
    uint256 duration;
}