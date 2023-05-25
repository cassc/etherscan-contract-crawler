// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

interface IStaking3 {
    function deposit(address _user, uint128 _amount, uint128 _stakeType) external payable returns(uint128,uint128, uint128);
    function compound(address _user, uint128 _stakeType) external payable returns(uint128,uint128, uint128);
    function withdraw(address _user, uint128 _amount, uint128 _stakeType) external payable returns(uint128,uint128, uint128);
    function claim(address _user, uint128 _stakeType) external payable returns(uint128,uint128);
    function addStakedType(uint128 _stakePeriod, uint128 _depositFees, uint128 _withdrawalFees, uint128 _rewardRate) external returns(uint128);
    function updateStakeType(uint128 _stakeType, uint128 _stakePeriod, uint128 _depositFees, uint128 _withdrawalFees, uint128 _rewardRate) external;
    function deleteStakeType(uint128 _stakeType) external returns(bool);
    function emergencyWithdraw(address _user, uint128 _stakeType) external payable returns(uint128,uint128,uint128);
    function updateEmergencyFees(uint128 newFee) external ;
    function updatePlatformFee(uint128 newFee) external;
    function updateOwnerWallet(address newOwnerWallet) external;
    function updateTreasuryWallet(address newTreasurywallet) external;
    function updateStakeLimit(uint128 _newLimit) external;
    function getPoolLength() external view returns(uint128);
}