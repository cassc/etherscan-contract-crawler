// SPDX-License-Identifier: CAL
pragma solidity ^0.8.0;

import {IERC20Upgradeable as IERC20} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import {SafeERC20Upgradeable as SafeERC20} from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import {MathUpgradeable as Math} from "@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol";

import "rain.interface.orderbook/ierc3156/IERC3156FlashBorrower.sol";
import "rain.interface.orderbook/ierc3156/IERC3156FlashLender.sol";

/// Thrown when `flashLoan` token is zero address.
error ZeroToken();

/// Thrown when `flashLoadn` receiver is zero address.
error ZeroReceiver();

/// Thrown when the `onFlashLoan` callback returns anything other than
/// ON_FLASH_LOAN_CALLBACK_SUCCESS.
/// @param result The value that was returned by `onFlashLoan`.
error FlashLenderCallbackFailed(bytes32 result);

/// Thrown when more than one debt is attempted simultaneously.
/// @param receiver The receiver of the active debt.
/// @param token The token of the active debt.
/// @param amount The amount of the active debt.
error ActiveDebt(address receiver, address token, uint256 amount);

/// @dev Flash fee is always 0 for orderbook as there's no entity to take
/// revenue for `Orderbook` and its more important anyway that flashloans happen
/// to connect external liquidity to live orders via arbitrage.
uint256 constant FLASH_FEE = 0;

/// @title OrderBookFlashLender
/// @notice Implements `IERC3156FlashLender` for `OrderBook`. Based on the
/// reference implementation by Alberto Cuesta Cañada found at
/// https://eips.ethereum.org/EIPS/eip-3156
/// Several features found in the reference implementation are simplified or
/// hardcoded for `Orderbook`.
contract OrderBookFlashLender is IERC3156FlashLender {
    using SafeERC20 for IERC20;
    using Math for uint256;

    IERC3156FlashBorrower private _receiver = IERC3156FlashBorrower(address(0));
    address private _token = address(0);
    uint256 private _amount = 0;

    function _isActiveDebt() internal view returns (bool) {
        return (address(_receiver) != address(0) ||
            _token != address(0) ||
            _amount != 0);
    }

    function _checkActiveDebt() internal view {
        if (_isActiveDebt()) {
            revert ActiveDebt(address(_receiver), _token, _amount);
        }
    }

    /// Whenever `Orderbook` sends tokens to any address it MUST first attempt
    /// to decrease any outstanding flash loans for that address. Consider the
    /// case that Alice deposits 100 TKN and she is the only depositor of TKN
    /// then flash borrows 100 TKN. If she attempts to withdraw 100 TKN during
    /// her `onFlashLoan` callback then `Orderbook`:
    ///
    /// - has 0 TKN balance to process the withdrawal
    /// - MUST process the withdrawal as Alice has the right to withdraw her
    /// balance at any time
    /// - Has the 100 TKN debt active under Alice
    ///
    /// In this case `Orderbook` can simply forgive Alice's 100 TKN debt instead
    /// of actually transferring any tokens. The withdrawal can decrease her
    /// vault balance by 100 TKN decoupled from needing to know whether a
    /// tranfer or forgiveness happened.
    ///
    /// The same logic applies to withdrawals as sending tokens during
    /// `takeOrders` as the reason for sending tokens is irrelevant, all that
    /// matters is that `Orderbook` prioritises debt repayments over external
    /// transfers.
    ///
    /// If there is an active debt that only partially eclipses the withdrawal
    /// then the debt will be fully repaid and the remainder transferred as a
    /// real token transfer.
    ///
    /// Note that Alice can still contrive a situation that causes `Orderbook`
    /// to attempt to send tokens that it does not have. If Alice can write a
    /// smart contract to trigger withdrawals she can flash loan 100% of the
    /// TKN supply in `Orderbook` and trigger her contract to attempt a
    /// withdrawal. For any normal ERC20 token this will fail and revert as the
    /// `Orderbook` cannot send tokens it does not have under any circumstances,
    /// but the scenario is worth being aware of for more exotic token
    /// behaviours that may not be supported.
    ///
    /// @param token_ The token being sent or for the debt being paid.
    /// @param receiver_ The receiver of the token or holder of the debt.
    /// @param sendAmount_ The amount to send or repay.
    function _decreaseFlashDebtThenSendToken(
        address token_,
        address receiver_,
        uint256 sendAmount_
    ) internal {
        // If this token transfer matches the active debt then prioritise
        // reducing debt over sending tokens.
        if (token_ == _token && receiver_ == address(_receiver)) {
            uint256 debtReduction_ = sendAmount_.min(_amount);
            sendAmount_ -= debtReduction_;

            // Even if this completely zeros the amount the debt is considered
            // active until the `flashLoan` also clears the token and recipient.
            _amount -= debtReduction_;
        }

        if (sendAmount_ > 0) {
            IERC20(token_).safeTransfer(receiver_, sendAmount_);
        }
    }

    /// @inheritdoc IERC3156FlashLender
    function flashLoan(
        IERC3156FlashBorrower receiver_,
        address token_,
        uint256 amount_,
        bytes calldata data_
    ) external override returns (bool) {
        // This prevents reentrancy, loans can be taken sequentially within a
        // transaction but not simultanously.
        _checkActiveDebt();

        // Set the active debt before transferring tokens to prevent reeentrancy.
        // The active debt is set beyond the scope of `flashLoan` to facilitate
        // early repayment via. `_decreaseFlashDebtThenSendToken`.
        {
            if (token_ == address(0)) {
                revert ZeroToken();
            }
            if (address(receiver_) == address(0)) {
                revert ZeroReceiver();
            }
            _token = token_;
            _receiver = receiver_;
            _amount = amount_;
            if (amount_ > 0) {
                IERC20(token_).safeTransfer(address(receiver_), amount_);
            }
        }

        bytes32 result_ = receiver_.onFlashLoan(
            // initiator
            msg.sender,
            // token
            token_,
            // amount
            amount_,
            // fee
            0,
            // data
            data_
        );
        if (result_ != ON_FLASH_LOAN_CALLBACK_SUCCESS) {
            revert FlashLenderCallbackFailed(result_);
        }

        // Pull tokens before releasing the active debt to prevent a new loan
        // from being taken reentrantly during the repayment of the current loan.
        {
            // Sync local `amount_` with global `_amount` in case an early
            // repayment was made during the loan term via.
            // `_decreaseFlashDebtThenSendToken`.
            amount_ = _amount;
            if (amount_ > 0) {
                IERC20(_token).safeTransferFrom(
                    address(_receiver),
                    address(this),
                    amount_
                );
                _amount = 0;
            }

            // Both of these are required to fully clear the active debt and
            // allow new debts.
            _receiver = IERC3156FlashBorrower(address(0));
            _token = address(0);
        }

        // Guard against some bad code path that allowed an active debt to remain
        // at this point. Should be impossible.
        _checkActiveDebt();

        return true;
    }

    /// @inheritdoc IERC3156FlashLender
    function flashFee(
        address,
        uint256
    ) external pure override returns (uint256) {
        return FLASH_FEE;
    }

    /// There's no limit to the size of a flash loan from `Orderbook` other than
    /// the current tokens deposited in `Orderbook`. If there is an active debt
    /// then loans are disabled so the max becomes `0` until after repayment.
    /// @inheritdoc IERC3156FlashLender
    function maxFlashLoan(
        address token_
    ) external view override returns (uint256) {
        return _isActiveDebt() ? 0 : IERC20(token_).balanceOf(address(this));
    }
}