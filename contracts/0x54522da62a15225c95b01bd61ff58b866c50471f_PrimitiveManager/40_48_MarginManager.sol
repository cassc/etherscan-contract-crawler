// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.6;

import "@primitivefi/rmm-core/contracts/interfaces/engine/IPrimitiveEngineActions.sol";
import "@primitivefi/rmm-core/contracts/interfaces/engine/IPrimitiveEngineView.sol";
import "../interfaces/IMarginManager.sol";
import "./CashManager.sol";
import "../libraries/TransferHelper.sol";
import "../libraries/Margin.sol";

/// @title   MarginManager contract
/// @author  Primitive
/// @notice  Manages the margins
abstract contract MarginManager is IMarginManager, CashManager {
    using TransferHelper for IERC20;
    using Margin for Margin.Data;

    /// @inheritdoc IMarginManager
    mapping(address => mapping(address => Margin.Data)) public override margins;

    /// EFFECT FUNCTIONS ///

    /// @inheritdoc IMarginManager
    function deposit(
        address recipient,
        address risky,
        address stable,
        uint256 delRisky,
        uint256 delStable
    ) external payable override lock {
        if (delRisky == 0 && delStable == 0) revert ZeroDelError();

        address engine = EngineAddress.computeAddress(factory, risky, stable);
        if (engine.code.length == 0) revert EngineAddress.EngineNotDeployedError();

        IPrimitiveEngineActions(engine).deposit(
            address(this),
            delRisky,
            delStable,
            abi.encode(CallbackData({payer: msg.sender, risky: risky, stable: stable}))
        );

        margins[recipient][engine].deposit(delRisky, delStable);

        emit Deposit(msg.sender, recipient, engine, risky, stable, delRisky, delStable);
    }

    /// @inheritdoc IMarginManager
    function withdraw(
        address recipient,
        address engine,
        uint256 delRisky,
        uint256 delStable
    ) external override lock {
        if (delRisky == 0 && delStable == 0) revert ZeroDelError();

        // Reverts the call early if margins are insufficient
        margins[msg.sender][engine].withdraw(delRisky, delStable);

        // Setting address(0) as the recipient will result in the tokens
        // being sent into the contract itself, useful to unwrap WETH for example
        IPrimitiveEngineActions(engine).withdraw(
            recipient == address(0) ? address(this) : recipient,
            delRisky,
            delStable
        );

        emit Withdraw(
            msg.sender,
            recipient == address(0) ? msg.sender : recipient,
            engine,
            IPrimitiveEngineView(engine).risky(),
            IPrimitiveEngineView(engine).stable(),
            delRisky,
            delStable
        );
    }

    /// CALLBACK IMPLEMENTATIONS ///

    /// @inheritdoc IPrimitiveDepositCallback
    function depositCallback(
        uint256 delRisky,
        uint256 delStable,
        bytes calldata data
    ) external override {
        CallbackData memory decoded = abi.decode(data, (CallbackData));

        address engine = EngineAddress.computeAddress(factory, decoded.risky, decoded.stable);
        if (msg.sender != engine) revert NotEngineError();

        if (delStable != 0) pay(decoded.stable, decoded.payer, msg.sender, delStable);
        if (delRisky != 0) pay(decoded.risky, decoded.payer, msg.sender, delRisky);
    }
}