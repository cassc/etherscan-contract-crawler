// SPDX-License-Identifier: ISC

pragma solidity ^0.8.13;

interface ICrvDepositor {
    //deposit crv for cvxCrv
    //can locking immediately or defer locking to someone else by paying a fee.
    //while users can choose to lock or defer, this is mostly in place so that
    //the cvx reward contract isnt costly to claim rewards
    function deposit(uint256 _amount, bool _lock) external;
}