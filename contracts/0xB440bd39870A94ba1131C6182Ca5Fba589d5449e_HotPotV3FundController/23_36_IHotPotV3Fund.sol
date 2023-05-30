// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

import './IHotPotV3FundERC20.sol';
import './fund/IHotPotV3FundEvents.sol';
import './fund/IHotPotV3FundState.sol';
import './fund/IHotPotV3FundUserActions.sol';
import './fund/IHotPotV3FundManagerActions.sol';

/// @title Hotpot V3 基金接口
/// @notice 接口定义分散在多个接口文件
interface IHotPotV3Fund is 
    IHotPotV3FundERC20, 
    IHotPotV3FundEvents, 
    IHotPotV3FundState, 
    IHotPotV3FundUserActions, 
    IHotPotV3FundManagerActions
{    
}