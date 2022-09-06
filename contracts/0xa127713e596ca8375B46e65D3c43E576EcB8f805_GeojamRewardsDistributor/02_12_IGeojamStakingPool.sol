// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.11;

interface IGeojamStakingPool {

    function getAmountStakedByUserInPool(uint256 _projectId, uint256 _poolId, address _address) external view returns(uint256);

    function didUserWithdrawFunds(uint256 _projectId, uint256 _poolId, address _address) external view returns(bool);

    function userStakedAmount(uint256 _projectId, uint256 _poolId, address _address) external view returns (uint256);
}