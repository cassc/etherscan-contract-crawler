/*
    Copyright 2022 JOJO Exchange
    SPDX-License-Identifier: Apache-2.0
*/

pragma solidity 0.8.9;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../intf/IPerpetual.sol";
import "../intf/IMarkPriceSource.sol";
import "../utils/SignedDecimalMath.sol";
import "../utils/Errors.sol";
import "./Liquidation.sol";
import "./Types.sol";

library Funding {
    using SafeERC20 for IERC20;

    // ========== events ==========

    event Deposit(
        address indexed to,
        address indexed payer,
        uint256 primaryAmount,
        uint256 secondaryAmount
    );

    event Withdraw(
        address indexed to,
        address indexed payer,
        uint256 primaryAmount,
        uint256 secondaryAmount
    );

    event RequestWithdraw(
        address indexed payer,
        uint256 primaryAmount,
        uint256 secondaryAmount,
        uint256 executionTimestamp
    );

    event TransferIn(
        address trader,
        uint256 primaryAmount,
        uint256 secondaryAmount
    );

    event TransferOut(
        address trader,
        uint256 primaryAmount,
        uint256 secondaryAmount
    );

    // ========== deposit ==========

    function deposit(
        Types.State storage state,
        uint256 primaryAmount,
        uint256 secondaryAmount,
        address to
    ) external {
        if (primaryAmount > 0) {
            IERC20(state.primaryAsset).safeTransferFrom(
                msg.sender,
                address(this),
                primaryAmount
            );
            state.primaryCredit[to] += int256(primaryAmount);
        }
        if (secondaryAmount > 0) {
            IERC20(state.secondaryAsset).safeTransferFrom(
                msg.sender,
                address(this),
                secondaryAmount
            );
            state.secondaryCredit[to] += secondaryAmount;
        }
        emit Deposit(to, msg.sender, primaryAmount, secondaryAmount);
    }

    // ========== withdraw ==========

    function requestWithdraw(
        Types.State storage state,
        uint256 primaryAmount,
        uint256 secondaryAmount
    ) external {
        state.pendingPrimaryWithdraw[msg.sender] = primaryAmount;
        state.pendingSecondaryWithdraw[msg.sender] = secondaryAmount;
        state.withdrawExecutionTimestamp[msg.sender] =
            block.timestamp +
            state.withdrawTimeLock;
        emit RequestWithdraw(
            msg.sender,
            primaryAmount,
            secondaryAmount,
            state.withdrawExecutionTimestamp[msg.sender]
        );
    }

    function executeWithdraw(
        Types.State storage state,
        address to,
        bool isInternal
    ) external {
        require(
            state.withdrawExecutionTimestamp[msg.sender] <= block.timestamp,
            Errors.WITHDRAW_PENDING
        );
        uint256 primaryAmount = state.pendingPrimaryWithdraw[msg.sender];
        uint256 secondaryAmount = state.pendingSecondaryWithdraw[msg.sender];
        state.pendingPrimaryWithdraw[msg.sender] = 0;
        state.pendingSecondaryWithdraw[msg.sender] = 0;
        // No need to change withdrawExecutionTimestamp, because we set pending
        // withdraw amount to 0.
        _withdraw(
            state,
            msg.sender,
            to,
            primaryAmount,
            secondaryAmount,
            isInternal
        );
    }

    function _withdraw(
        Types.State storage state,
        address payer,
        address to,
        uint256 primaryAmount,
        uint256 secondaryAmount,
        bool isInternal
    ) private {
        if (primaryAmount > 0) {
            state.primaryCredit[payer] -= int256(primaryAmount);
            if (isInternal) {
                state.primaryCredit[to] += int256(primaryAmount);
            } else {
                IERC20(state.primaryAsset).safeTransfer(to, primaryAmount);
            }
        }
        if (secondaryAmount > 0) {
            state.secondaryCredit[payer] -= secondaryAmount;
            if (isInternal) {
                state.secondaryCredit[to] += secondaryAmount;
            } else {
                IERC20(state.secondaryAsset).safeTransfer(to, secondaryAmount);
            }
        }

        if (primaryAmount > 0) {
            // if trader withdraw primary asset, we should check if solid safe
            require(
                Liquidation._isSolidSafe(state, payer),
                Errors.ACCOUNT_NOT_SAFE
            );
        } else {
            // if trader didn't withdraw primary asset, normal safe check is enough
            require(Liquidation._isSafe(state, payer), Errors.ACCOUNT_NOT_SAFE);
        }

        if (isInternal) {
            emit TransferIn(to, primaryAmount, secondaryAmount);
            emit TransferOut(payer, primaryAmount, secondaryAmount);
        } else {
            emit Withdraw(to, payer, primaryAmount, secondaryAmount);
        }
    }
}