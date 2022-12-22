/// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.11;

interface IDepositor {
    function deposit(
        uint256 amount,
        bool lock,
        bool stake,
        address user
    ) external;

    function deposit(
        address _staker,
        uint256 _amount,
        bool _earn
    ) external;

    function liquidityGauge() external returns (address);

    function gauge() external returns (address);
}