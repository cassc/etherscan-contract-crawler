// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.17;

import {TokenUtils, Constants} from "src/common/TokenUtils.sol";
import {IAngleStableMaster} from "src/interfaces/IAngleStableMaster.sol";

/// @title AngleLiquidityProviding
/// @notice Enables to add/remove liquidity to/from the Angle Stable Master.
abstract contract AngleLiquidityProviding {
    /// @notice Angle Stable Master contract address.
    address internal constant STABLE_MASTER = 0x5adDc89785D75C86aB939E9e15bfBBb7Fc086A87;

    /// @notice Adds liquidity to the Angle Stable Master.
    /// @param token Token address.
    /// @param underlyingAmount Amount of token to add.
    /// @param poolManager Pool manager address.
    /// @param recipient Recipient address.
    function addLiquidity(address token, uint256 underlyingAmount, address poolManager, address recipient) external {
        if (recipient == Constants.MSG_SENDER) recipient = msg.sender;
        else if (recipient == Constants.ADDRESS_THIS) recipient = address(this);

        underlyingAmount = TokenUtils._amountIn(underlyingAmount, token);
        if (underlyingAmount != 0) TokenUtils._approve(token, STABLE_MASTER);

        IAngleStableMaster(STABLE_MASTER).deposit(underlyingAmount, recipient, poolManager);
    }

    /// @notice Removes liquidity from the Angle Stable Master.
    /// @param lpToken LP token address.
    /// @param underlyingAmount Amount of LP token to remove.
    /// @param poolManager Pool manager address.
    /// @param recipient Recipient address.
    function removeLiquidity(address lpToken, uint256 underlyingAmount, address poolManager, address recipient)
        external
    {
        if (recipient == Constants.MSG_SENDER) recipient = msg.sender;
        else if (recipient == Constants.ADDRESS_THIS) recipient = address(this);

        underlyingAmount = TokenUtils._amountIn(underlyingAmount, lpToken);

        IAngleStableMaster(STABLE_MASTER).withdraw(underlyingAmount, address(this), recipient, poolManager);
    }
}