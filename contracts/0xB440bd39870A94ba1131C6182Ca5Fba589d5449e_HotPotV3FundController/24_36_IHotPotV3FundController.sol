// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

import './controller/IManagerActions.sol';
import './controller/IGovernanceActions.sol';
import './controller/IControllerState.sol';
import './controller/IControllerEvents.sol';

/// @title Hotpot V3 控制合约接口定义.
/// @notice 基金经理和治理均需通过控制合约进行操作.
interface IHotPotV3FundController is IManagerActions, IGovernanceActions, IControllerState, IControllerEvents {
    /// @notice 基金分成全部用于销毁HPT
    /// @dev 任何人都可以调用本函数
    /// @param token 用于销毁时购买HPT的代币类型
    /// @param amount 代币数量
    /// @return burned 销毁数量
    function harvest(address token, uint amount) external returns(uint burned);
}