// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

contract IStakingPlatform {
    struct Stake {
        address staker;
        uint256 stakedSTK;
        uint256 stakeTime;
        uint256 pendingRewards;
        int256 firstTokenId;
        int256 secondTokenId;
        uint16 apy;
        bool staked;
    }

    event StakeToken(
        address indexed stakeholder,
        uint256 amount
    );

    event StakeNFT(
        address indexed stakeholder,
        uint16 boostedAPY
    );

    event UnStaked(
        address indexed stakeholder,
        uint256 amount,
        uint256 reward
    );
}