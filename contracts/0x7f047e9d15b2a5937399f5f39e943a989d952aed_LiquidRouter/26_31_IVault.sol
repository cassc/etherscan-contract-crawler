// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.17;

interface IVault {
    function deposit(address _staker, uint256 _amount, bool _earn) external;
}