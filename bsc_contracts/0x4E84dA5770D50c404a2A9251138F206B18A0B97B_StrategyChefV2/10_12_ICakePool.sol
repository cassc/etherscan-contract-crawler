// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface ICakePool {
    function poolLength() external view returns (uint256);

    function userInfo() external view returns (uint256);

    // Return reward multiplier over the given _from to _to block.
    function getMultiplier(uint256 _from, uint256 _to)
    external
    view
    returns (uint256);

    // View function to see pending CAKEs on frontend.
    function pendingCake(uint256 _pid, address _user)
    external
    view
    returns (uint256);

    // Deposit LP tokens to MasterChef for CAKE allocation.
    function deposit(uint256 _amount, uint256 _lockDuration) external;

    // Withdraw LP tokens from MasterChef.
    function withdrawByAmount(uint256 _amount) external;

    function withdrawAll() external;

}