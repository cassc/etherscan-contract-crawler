//SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

interface IStaking {
    function userStake(address user)
        external
        view
        returns (
            uint256 _sum,
            uint256 _bonus,
            uint256 _stake
        );
}

interface IStakingOwn {
    struct StakeRecord {
        uint256 day;
        uint256 totalAmount;
        uint256 lockedAmount;
        uint256 unlockedAmount;
        uint256 previousAmount;
        uint256 reservedReward;
        uint256 claimedDay;
    }

    function userStakes(address user)
        external
        view
        returns (StakeRecord memory);
}