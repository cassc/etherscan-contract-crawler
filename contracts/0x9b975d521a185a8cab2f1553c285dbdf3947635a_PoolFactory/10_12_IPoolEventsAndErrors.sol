// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

interface IPoolEventsAndErrors {
    event Deposit(address depositor, uint256[] ids);
    event Withdraw(address withdrawer, uint256[] ids);
    event Swap(address user, uint256[] depositIDs, uint256[] withdrawIDs);

    error NoStake();
    error NotEnoughStake();
    error NotValidCollection();
    error NotEnoughForSwap();
    error FeeRequired();
    error RefundFailed();
    error TransferFeesFailed();
}