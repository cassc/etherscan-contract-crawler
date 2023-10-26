// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.16;

interface IOperatorRewardsCollector {
    // events
    event UpdatedStaderConfig(address indexed staderConfig);
    event Claimed(address indexed receiver, uint256 amount);
    event DepositedFor(address indexed sender, address indexed receiver, uint256 amount);

    // methods

    function depositFor(address _receiver) external payable;

    function claim() external;
}