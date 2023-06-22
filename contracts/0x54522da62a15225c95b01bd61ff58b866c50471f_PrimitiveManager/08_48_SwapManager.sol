// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.6;

import "@primitivefi/rmm-core/contracts/interfaces/engine/IPrimitiveEngineActions.sol";
import "@primitivefi/rmm-core/contracts/interfaces/engine/IPrimitiveEngineView.sol";
import "@primitivefi/rmm-core/contracts/libraries/ReplicationMath.sol";

import "../interfaces/ISwapManager.sol";
import "../interfaces/external/IERC20.sol";
import "./MarginManager.sol";
import "./CashManager.sol";

/// @title   SwapManager contract
/// @author  Primitive
/// @dev     Manages the swaps
abstract contract SwapManager is ISwapManager, CashManager, MarginManager {
    using TransferHelper for IERC20;
    using Margin for Margin.Data;

    /// @notice Reverts the transaction is the deadline is reached
    modifier checkDeadline(uint256 deadline) {
        if (block.timestamp > deadline) revert DeadlineReachedError();
        _;
    }

    /// EFFECT FUNCTIONS ///

    /// @inheritdoc ISwapManager
    function swap(SwapParams calldata params) external payable override lock checkDeadline(params.deadline) {
        CallbackData memory callbackData = CallbackData({
            payer: msg.sender,
            risky: params.risky,
            stable: params.stable
        });

        address engine = EngineAddress.computeAddress(factory, params.risky, params.stable);
        if (engine.code.length == 0) revert EngineAddress.EngineNotDeployedError();

        IPrimitiveEngineActions(engine).swap(
            params.toMargin ? address(this) : params.recipient,
            params.poolId,
            params.riskyForStable,
            params.deltaIn,
            params.deltaOut,
            params.fromMargin,
            params.toMargin,
            abi.encode(callbackData)
        );

        if (params.fromMargin) {
            margins[msg.sender][engine].withdraw(
                params.riskyForStable ? params.deltaIn : 0,
                params.riskyForStable ? 0 : params.deltaIn
            );
        }

        if (params.toMargin) {
            margins[params.recipient][engine].deposit(
                params.riskyForStable ? 0 : params.deltaOut,
                params.riskyForStable ? params.deltaOut : 0
            );
        }

        emit Swap(
            msg.sender,
            params.recipient,
            engine,
            params.poolId,
            params.riskyForStable,
            params.deltaIn,
            params.deltaOut,
            params.fromMargin,
            params.toMargin
        );
    }

    /// CALLBACK IMPLEMENTATIONS ///

    /// @inheritdoc IPrimitiveSwapCallback
    function swapCallback(
        uint256 delRisky,
        uint256 delStable,
        bytes calldata data
    ) external override {
        CallbackData memory decoded = abi.decode(data, (CallbackData));

        address engine = EngineAddress.computeAddress(factory, decoded.risky, decoded.stable);
        if (msg.sender != engine) revert NotEngineError();

        if (delRisky != 0) pay(decoded.risky, decoded.payer, msg.sender, delRisky);
        if (delStable != 0) pay(decoded.stable, decoded.payer, msg.sender, delStable);
    }
}