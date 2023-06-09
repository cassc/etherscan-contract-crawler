// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

interface IBridge {
    event Locked(address indexed sender, uint256 amount);
    event Unlocked(address indexed sender, uint256 amount);

    function lock(uint256 amount) external payable;
    function unlock(address account, uint256 amount, bytes32 hash) external;
    function isUnlockCompleted(bytes32 hash) external view returns (bool);
}