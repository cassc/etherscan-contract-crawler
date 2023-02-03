// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IStrategy {
    //deposits all funds into the farm
    function deposit() external;

    //vault only - withdraws funds from the strategy
    function withdraw(uint256 _amount, address _user) external;

    //claims rewards, charges fees, and re-deposits; returns caller fee amount.
    function harvest() external returns (uint256);

    //returns the balance of all tokens managed by the strategy
    function balanceOf() external view returns (uint256);

    //pauses deposits, resets allowances, and withdraws all funds from farm
    function panic() external;

    //pauses deposits and resets allowances
    function pause() external;

    //unpauses deposits and maxes out allowances again
    function unpause() external;
}