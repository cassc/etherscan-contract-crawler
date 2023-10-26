// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

interface IVeUnoDaoYieldDistributor {
    function notifyRewardAmount(uint256 amount) external;

    function yieldDuration() external view returns (uint256);

    function periodFinish() external view returns (uint256);

    function yieldRate() external view returns (uint256);
}