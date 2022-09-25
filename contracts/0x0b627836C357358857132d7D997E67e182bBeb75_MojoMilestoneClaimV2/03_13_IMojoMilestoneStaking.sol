//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;


interface IMojoMilestoneStaking {

    struct StakeState {
        uint256 claimableReward;
        uint256 volume;
        uint256 maskRay;
        uint256 lastPeriod;
    }

    struct PeriodState {
        uint256 rewardPerSec;
        uint256 periodStart;
        uint256 periodLength;
        uint256 totalVolume;
        uint256 roundMaskRay;
        uint256 lastUpdate;
    }

    event TotalVolumeChanged(uint256 volume);
    event AccountVolumeChanged(address indexed account,uint256 volume);

    event TokenClaimed(address indexed account, uint256 amount);

    function stake(address owner, uint256 tokenId, uint256 amount) external;

    function withdrawRewards() external;
}