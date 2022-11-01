// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IStakeManager {
    
    struct UserInfo {

        uint256 totalStakedDefault; //linear
        uint256 totalStakedAutoCompound;

        uint256 walletStartTime;
        uint256 overThresholdTimeCounter;

        uint256 activeStakesCount;
        uint256 withdrawStakesCount;

        mapping(uint256 => StakeInfo) activeStakes;
        mapping(uint256 => WithdrawnStakeInfo) withdrawnStakes;

    }

    struct WithdrawnStakeInfo {
        uint256 amount;
        uint256 taxReduction;
    }


    struct StakeInfo {
        uint256 amount;
        uint256 startTime;
        bool isAutoPool;
    } // todo find a way to refactor

    function saveStake(address _user, uint256 _amount, bool isAutoCompound) external;
    function withdrawFromStake(address _user,uint256 _amount, uint256 _stakeID) external;
    function getUserStake(address _user, uint256 _stakeID) external view returns (StakeInfo memory);
    function getActiveStakeTaxReduction(address _user, uint256 _stakeID) external view returns (uint256);
    function getWithdrawnStakeTaxReduction(address _user, uint256 _stakeID) external view returns (uint256);
    function isStakeAutoPool(address _user, uint256 _stakeID) external view returns (bool);
    function totalStaked(address _user) external view returns (uint256);
    function utilizeWithdrawnStake(address _user, uint256 _amount, uint256 _stakeID) external;
}