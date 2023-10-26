// SPDX-License-Identifier: MIT
// Latest stable version of solidity
pragma solidity 0.8.12;

interface IFarm {
    function payment(address buyer, uint256 amount) external returns (bool);

    function rewardedStones(address staker) external view returns (uint256);
}