// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

interface IBalDepositWrapper {
    function deposit(
        uint256 _amount,
        uint256 _minOut,
        bool _lock,
        address _stakeAddress
    ) external;
}