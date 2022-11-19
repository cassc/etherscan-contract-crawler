// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.15;

import {ERC20} from "solmate/tokens/ERC20.sol";
import {ReentrancyGuard} from "solmate/utils/ReentrancyGuard.sol";

import {TransferHelper} from "libraries/TransferHelper.sol";

import {TRSRYv1} from "src/modules/TRSRY/TRSRY.v1.sol";
import "src/Kernel.sol";

/// @notice Treasury holds all other assets under the control of the protocol.
contract OlympusTreasury is TRSRYv1, ReentrancyGuard {
    using TransferHelper for ERC20;

    //============================================================================================//
    //                                      MODULE SETUP                                          //
    //============================================================================================//

    constructor(Kernel kernel_) Module(kernel_) {
        active = true;
    }

    /// @inheritdoc Module
    function KEYCODE() public pure override returns (Keycode) {
        return toKeycode("TRSRY");
    }

    /// @inheritdoc Module
    function VERSION() external pure override returns (uint8 major, uint8 minor) {
        major = 1;
        minor = 0;
    }

    //============================================================================================//
    //                                       CORE FUNCTIONS                                       //
    //============================================================================================//

    /// @inheritdoc TRSRYv1
    function increaseWithdrawApproval(
        address withdrawer_,
        ERC20 token_,
        uint256 amount_
    ) external override permissioned {
        uint256 approval = withdrawApproval[withdrawer_][token_];

        uint256 newAmount = type(uint256).max - approval <= amount_
            ? type(uint256).max
            : approval + amount_;
        withdrawApproval[withdrawer_][token_] = newAmount;

        emit IncreaseWithdrawApproval(withdrawer_, token_, newAmount);
    }

    /// @inheritdoc TRSRYv1
    function decreaseWithdrawApproval(
        address withdrawer_,
        ERC20 token_,
        uint256 amount_
    ) external override permissioned {
        uint256 approval = withdrawApproval[withdrawer_][token_];

        uint256 newAmount = approval <= amount_ ? 0 : approval - amount_;
        withdrawApproval[withdrawer_][token_] = newAmount;

        emit DecreaseWithdrawApproval(withdrawer_, token_, newAmount);
    }

    /// @inheritdoc TRSRYv1
    function withdrawReserves(
        address to_,
        ERC20 token_,
        uint256 amount_
    ) public override permissioned onlyWhileActive {
        withdrawApproval[msg.sender][token_] -= amount_;

        token_.safeTransfer(to_, amount_);

        emit Withdrawal(msg.sender, to_, token_, amount_);
    }

    // =========  DEBT FUNCTIONS ========= //

    /// @inheritdoc TRSRYv1
    function increaseDebtorApproval(
        address debtor_,
        ERC20 token_,
        uint256 amount_
    ) external override permissioned {
        uint256 newAmount = debtApproval[debtor_][token_] + amount_;
        debtApproval[debtor_][token_] = newAmount;
        emit IncreaseDebtorApproval(debtor_, token_, newAmount);
    }

    /// @inheritdoc TRSRYv1
    function decreaseDebtorApproval(
        address debtor_,
        ERC20 token_,
        uint256 amount_
    ) external override permissioned {
        uint256 newAmount = debtApproval[debtor_][token_] - amount_;
        debtApproval[debtor_][token_] = newAmount;
        emit DecreaseDebtorApproval(debtor_, token_, newAmount);
    }

    /// @inheritdoc TRSRYv1
    function incurDebt(ERC20 token_, uint256 amount_)
        external
        override
        permissioned
        onlyWhileActive
    {
        debtApproval[msg.sender][token_] -= amount_;

        // Add debt to caller
        reserveDebt[token_][msg.sender] += amount_;
        totalDebt[token_] += amount_;

        token_.safeTransfer(msg.sender, amount_);

        emit DebtIncurred(token_, msg.sender, amount_);
    }

    /// @inheritdoc TRSRYv1
    function repayDebt(
        address debtor_,
        ERC20 token_,
        uint256 amount_
    ) external override permissioned nonReentrant {
        if (reserveDebt[token_][debtor_] == 0) revert TRSRY_NoDebtOutstanding();

        // Deposit from caller first (to handle nonstandard token transfers)
        uint256 prevBalance = token_.balanceOf(address(this));
        token_.safeTransferFrom(msg.sender, address(this), amount_);

        uint256 received = token_.balanceOf(address(this)) - prevBalance;

        // Choose minimum between passed-in amount and received amount
        if (received > amount_) received = amount_;

        // Subtract debt from debtor
        reserveDebt[token_][debtor_] -= received;
        totalDebt[token_] -= received;

        emit DebtRepaid(token_, debtor_, received);
    }

    /// @inheritdoc TRSRYv1
    function setDebt(
        address debtor_,
        ERC20 token_,
        uint256 amount_
    ) external override permissioned {
        uint256 oldDebt = reserveDebt[token_][debtor_];

        reserveDebt[token_][debtor_] = amount_;

        if (oldDebt < amount_) totalDebt[token_] += amount_ - oldDebt;
        else totalDebt[token_] -= oldDebt - amount_;

        emit DebtSet(token_, debtor_, amount_);
    }

    /// @inheritdoc TRSRYv1
    function deactivate() external override permissioned {
        active = false;
    }

    /// @inheritdoc TRSRYv1
    function activate() external override permissioned {
        active = true;
    }

    //============================================================================================//
    //                                       VIEW FUNCTIONS                                       //
    //============================================================================================//

    /// @inheritdoc TRSRYv1
    function getReserveBalance(ERC20 token_) external view override returns (uint256) {
        return token_.balanceOf(address(this)) + totalDebt[token_];
    }
}