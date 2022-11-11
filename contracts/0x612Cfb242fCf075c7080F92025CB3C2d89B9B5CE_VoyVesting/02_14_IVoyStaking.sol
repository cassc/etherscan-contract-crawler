// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IVoyStaking {
    function getMultiplier(uint256 _from, uint256 _to) external pure returns (uint256);

    function getPending(address _user) external view returns (uint256);

    function getRewardBalance() external view returns (uint256);

    function stake(uint256 _amount) external;

    function unStake(uint256 _amount) external returns (uint256);

    function getUnStakeFeePercent(address _user) external view returns (uint256);

    function harvest() external returns (uint256);
}