pragma solidity ^0.6.0;

interface ILockSubscription {
    function processLockEvent(
        address account,
        uint256 lockStart,
        uint256 lockEnd,
        uint256 amount
    ) external;
}