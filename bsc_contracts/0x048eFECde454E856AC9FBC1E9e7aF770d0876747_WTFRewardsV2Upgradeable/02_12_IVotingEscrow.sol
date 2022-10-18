// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IVotingEscrow {
    function createLock(uint256 _amount, uint256 duration) external;

    function createLockFor(
        address _account,
        uint256 _amount,
        uint256 _duration
    ) external;

    function getLockedAmount(address account) external view returns (uint256);

    function increaseLockDuration(uint256 _newExpiryTimestamp) external;

    function increaseLockDurationFor(
        address account,
        uint256 _newExpiryTimestamp
    ) external;

    function increaseTimeAndAmount(uint256 _amount, uint256 _newExpiryTimestamp)
        external;

    function increaseTimeAndAmountFor(
        address _account,
        uint256 _amount,
        uint256 _newExpiryTimestamp
    ) external;

    function increaseAmount(uint256 _amount) external;

    function increaseAmountFor(address _account, uint256 _amount) external;

    function isLockExpired(address account) external view returns (bool);
}