/// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

interface Events {
    error NotAuthorized();
    error NoZeroValues();
    error MaxStaked();

    error NotCollecting();  
    error NotStaking();
    error NotCompleted();

    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount, uint256 rewards);
    event ExitWithFees(address indexed user, uint256 amount);

    event StakingStarted();
    event StakingCompleted();
}