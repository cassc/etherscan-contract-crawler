// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title HotPotV3Controller 事件接口定义
interface IControllerEvents {
    /// @notice 当设置受信任token时触发
    event ChangeVerifiedToken(address indexed token, bool isVerified);

    /// @notice 当调用Harvest时触发
    event Harvest(address indexed token, uint amount, uint burned);

    /// @notice 当调用setHarvestPath时触发
    event SetHarvestPath(address indexed token, bytes path);

    /// @notice 当调用setGovernance时触发
    event SetGovernance(address indexed account);

    /// @notice 当调用setMaxSqrtSlippage时触发
    event SetMaxSqrtSlippage(uint sqrtSlippage);

    /// @notice 当调用setMaxPriceImpact时触发
    event SetMaxPriceImpact(uint priceImpact);
}