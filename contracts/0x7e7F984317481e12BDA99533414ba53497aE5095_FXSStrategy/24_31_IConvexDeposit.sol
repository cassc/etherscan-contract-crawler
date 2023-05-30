// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

interface IConvexDeposit {
    function depositAll(uint256 _pid, bool _stake) external returns (bool);

    function deposit(
        uint256 _pid,
        uint256 _amount,
        bool _stake
    ) external returns (bool);
}