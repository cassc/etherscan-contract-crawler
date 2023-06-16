//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IStruct {
    struct GeneralVariables {
        uint256 APR;
        uint256 maxGoalOfStaking;
        uint256 openTime;
        uint256 closeTime;
        uint256 penalty;
        uint256 maxStakeAmount;
        string title;
    }

    struct UserInfo {
        uint256 updateTime;
        uint256 previousReward;
        uint256 totalStakedAmount;
    }
}

interface IStaking is IStruct{
    function initStaking(GeneralVariables memory _generalInfo)
        external;
}