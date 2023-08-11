// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

// Actions open during the Crowdfund phase
interface ICaptainGuardEvents {
    // When new captain assigned
    event CaptainAssigned(address initiator, address indexed captain);
}