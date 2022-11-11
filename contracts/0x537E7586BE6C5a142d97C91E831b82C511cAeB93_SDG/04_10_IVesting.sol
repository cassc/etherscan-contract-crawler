// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

interface VestingEvents {
    event ClaimedToken(
        address userAddress,
        uint256 claimedAmount,
        uint8 claimCount
    );
}