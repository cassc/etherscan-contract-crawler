// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.16;

import './IStaderConfig.sol';

interface INodeELRewardVault {
    // errors
    error NotEnoughRewardToWithdraw();
    error ETHTransferFailed(address recipient, uint256 amount);

    // events
    event ETHReceived(address indexed sender, uint256 amount);
    event Withdrawal(uint256 protocolAmount, uint256 operatorAmount, uint256 userAmount);
    event UpdatedStaderConfig(address staderConfig);

    // methods
    function withdraw() external;
}