// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Hotpot V3 事件接口定义
interface IHotPotV3FundEvents {
    /// @notice 当存入基金token时，会触发该事件
    event Deposit(address indexed owner, uint amount, uint share);

    /// @notice 当取走基金token时，会触发该事件
    event Withdraw(address indexed owner, uint amount, uint share);

    /// @notice 当调用setDescriptor时触发
    event SetDescriptor(bytes descriptor);

    /// @notice 当调用setDepositDeadline时触发
    event SetDeadline(uint deadline);

    /// @notice 当调用setPath时触发
    event SetPath(address distToken, bytes path);

    /// @notice 当调用init时，会触发该事件
    event Init(uint poolIndex, uint positionIndex, uint amount);

    /// @notice 当调用add时，会触发该事件
    event Add(uint poolIndex, uint positionIndex, uint amount, bool collect);

    /// @notice 当调用sub时，会触发该事件
    event Sub(uint poolIndex, uint positionIndex, uint proportionX128);

    /// @notice 当调用move时，会触发该事件
    event Move(uint poolIndex, uint subIndex, uint addIndex, uint proportionX128);
}