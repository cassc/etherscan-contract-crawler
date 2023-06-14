// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IBasicStake {
    // 1.[Types: Basic]
    struct recdBasicUnit {
        uint256 nonce;
        uint256[] aryLKTime;
        uint256[] aryAmount;
        uint256[] aryLocked;
    }

    // 2.[Functions]
    function applyStake(
        address staker,
        uint256 nonce,
        uint256[] memory aryLKTime,
        uint256[] memory aryAmout
    ) external;

    function claimStake() external;

    // 3. [Events]
    event evApplyStake(
        address staker,
        uint256 nonce,
        uint256[] time,
        uint256[] amount
    );
    event evClaimStake(
        address staker,
        uint256 total,
        uint256[] time,
        uint256[] amount
    );
}