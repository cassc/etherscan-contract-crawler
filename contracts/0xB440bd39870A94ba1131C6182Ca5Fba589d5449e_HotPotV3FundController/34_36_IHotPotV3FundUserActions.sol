// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Hotpot V3 用户操作接口定义
/// @notice 存入(deposit)函数适用于ERC20基金; 如果是ETH基金(内部会转换为WETH9)，应直接向基金合约转账;
interface IHotPotV3FundUserActions {
    /// @notice 用户存入基金本币
    /// @param amount 存入数量
    /// @return share 用户获得的基金份额
    function deposit(uint amount) external returns(uint share);

    /// @notice 用户取出指定份额的本币
    /// @param share 取出的基金份额数量
    /// @param amountMin 最小提取值
    /// @param deadline 最晚交易时间
    /// @return amount 返回本币数量
    function withdraw(uint share, uint amountMin, uint deadline) external returns(uint amount);
}