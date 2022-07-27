// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

interface IVeLFT {
    function createLock(uint256, uint256) external;
    function increaseAmount(uint256) external;
    function increaseUnlockTime(uint256) external;
    function withdraw() external;
    function rewardPools(uint256) external view returns(address);
    function rewardPoolsLength() external view returns(uint256);
}