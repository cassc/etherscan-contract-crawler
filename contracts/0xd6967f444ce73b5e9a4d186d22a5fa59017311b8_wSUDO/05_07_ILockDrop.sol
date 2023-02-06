// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

interface ILockDrop {
    function lock(uint256 oldTokenAmount, address recipient) external returns (uint256 newTokenAmount);

    function unlock(address recipient) external returns (uint256 oldTokenAmount);

    function oldToken() external view returns (address);

    function newToken() external view returns (address);

    function unlockTimestamp() external view returns (uint64);
}