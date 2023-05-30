// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

import '../fund/IHotPotV3FundManagerActions.sol';

/// @title 控制器合约基金经理操作接口定义
interface IManagerActions {
    /// @notice 设置基金描述信息
    /// @dev This function can only be called by manager 
    /// @param _descriptor 描述信息
    function setDescriptor(address fund, bytes calldata _descriptor) external;

    /// @notice 设置基金存入截止时间
    /// @dev This function can only be called by manager 
    /// @param fund 基金地址
    /// @param deadline 最晚存入截止时间
    function setDepositDeadline(address fund, uint deadline) external;

    /// @notice 设置代币交易路径
    /// @dev This function can only be called by manager 
    /// @dev 设置路径时不能修改为0地址，且path路径里的token必须验证是否受信任
    /// @param fund 基金地址
    /// @param distToken 目标代币地址
    /// @param path 符合uniswap v3格式的交易路径
    function setPath(
        address fund, 
        address distToken, 
        bytes memory path
    ) external;

    /// @notice 初始化头寸, 允许投资额为0.
    /// @dev This function can only be called by manager
    /// @param fund 基金地址
    /// @param token0 token0 地址
    /// @param token1 token1 地址
    /// @param fee 手续费率
    /// @param tickLower 价格刻度下届
    /// @param tickUpper 价格刻度上届
    /// @param amount 初始化投入金额，允许为0, 为0表示仅初始化头寸，不作实质性投资
    /// @param deadline 最晚交易时间
    /// @return liquidity 添加的lp数量
    function init(
        address fund,
        address token0,
        address token1,
        uint24 fee,
        int24 tickLower,
        int24 tickUpper,
        uint amount,
        uint deadline
    ) external returns(uint128 liquidity);

    /// @notice 投资指定头寸，可选复投手续费
    /// @dev This function can only be called by manager 
    /// @param fund 基金地址
    /// @param poolIndex 池子索引号
    /// @param positionIndex 头寸索引号
    /// @param amount 投资金额
    /// @param collect 是否收集已产生的手续费并复投
    /// @param deadline 最晚交易时间
    /// @return liquidity 添加的lp数量
    function add(
        address fund,
        uint poolIndex,
        uint positionIndex, 
        uint amount, 
        bool collect,
        uint deadline
    ) external returns(uint128 liquidity);

    /// @notice 撤资指定头寸
    /// @dev This function can only be called by manager 
    /// @param fund 基金地址
    /// @param poolIndex 池子索引号
    /// @param positionIndex 头寸索引号
    /// @param proportionX128 撤资比例，左移128位; 允许为0，为0表示只收集手续费
    /// @param deadline 最晚交易时间
    /// @return amount 撤资获得的基金本币数量
    function sub(
        address fund,
        uint poolIndex,
        uint positionIndex,
        uint proportionX128,
        uint deadline
    ) external returns(uint amount);

    /// @notice 调整头寸投资
    /// @dev This function can only be called by manager 
    /// @param fund 基金地址
    /// @param poolIndex 池子索引号
    /// @param subIndex 要移除的头寸索引号
    /// @param addIndex 要添加的头寸索引号
    /// @param proportionX128 调整比例，左移128位
    /// @param deadline 最晚交易时间
    /// @return liquidity 调整后添加的lp数量
    function move(
        address fund,
        uint poolIndex,
        uint subIndex, 
        uint addIndex,
        uint proportionX128,
        uint deadline
    ) external returns(uint128 liquidity);
}