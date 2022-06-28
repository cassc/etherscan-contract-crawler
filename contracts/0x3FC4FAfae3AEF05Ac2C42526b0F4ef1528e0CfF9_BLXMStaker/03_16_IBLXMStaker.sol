// SPDX-License-Identifier: GPL-3.0 License

pragma solidity ^0.8.0;


interface IBLXMStaker {

    function BLXM() external view returns (address);

    function addRewards(uint totalBlxmAmount, uint16 supplyDays) external returns (uint amountPerHours);
    function stake(uint256 amount, address to, uint16 lockedDays) external;
    function withdraw(uint256 amount, address to, uint256 idx) external returns (uint256 rewardAmount);
}