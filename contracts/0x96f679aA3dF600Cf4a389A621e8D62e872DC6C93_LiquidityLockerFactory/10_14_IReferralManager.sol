// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

interface IReferralManager {
    function handleReferralForUser(
        address referrer,
        address user,
        uint256 amount
    ) external;
}