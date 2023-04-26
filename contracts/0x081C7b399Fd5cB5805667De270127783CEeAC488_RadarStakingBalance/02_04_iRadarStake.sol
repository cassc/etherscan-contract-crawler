// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.17;

interface iRadarStake {

    // store lock meta data
    struct Stake {
        uint256 totalStaked;
        uint256 lastStakedTimestamp;
        uint256 cooldownSeconds;
        uint256 cooldownTriggeredAtTimestamp;
    }

    struct Apr {
        uint256 startTime;
        uint256 endTime;
        uint256 apr; // e.g. 300 => 3%
    }

    function getAllAprs() external view returns(Apr[] memory);
    function getStake(address addr) external view returns (Stake memory);

    function addToStake(uint256 amount, address addr) external; // onlyStakingLogicContract
    function triggerUnstake(address addr) external; // onlyStakingLogicContract
    function removeFromStake(uint256 amount, address addr) external; // onlyStakingLogicContract
}