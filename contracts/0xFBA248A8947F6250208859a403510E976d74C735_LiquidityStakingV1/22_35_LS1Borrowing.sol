// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.2;
pragma abicoder v2;

import {SafeERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import {SafeMathUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import {IERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import {MathUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol";
import {LS1Types} from "../lib/LS1Types.sol";
import {SafeCast} from "../lib/SafeCast.sol";
import {LS1BorrowerAllocations} from "./LS1BorrowerAllocations.sol";
import {LS1Staking} from "./LS1Staking.sol";

/**
 * @title LS1Borrowing
 * @author MarginX
 *
 * @dev External functions for borrowers. See LS1BorrowerAllocations for details on
 *  borrower accounting.
 */
abstract contract LS1Borrowing is LS1Staking, LS1BorrowerAllocations {
    using SafeCast for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using SafeMathUpgradeable for uint256;

    // ============ Events ============

    event Borrowed(
        address indexed borrower,
        uint256 amount,
        uint256 newBorrowedBalance
    );

    event RepaidBorrow(
        address indexed borrower,
        address sender,
        uint256 amount,
        uint256 newBorrowedBalance
    );

    event RepaidDebt(
        address indexed borrower,
        address sender,
        uint256 amount,
        uint256 newDebtBalance
    );

    // ============ External Functions ============

    /**
     * @notice Borrow staked funds.
     *
     * @param  amount  The token amount to borrow.
     */
    function borrow(uint256 amount) external nonReentrant {
        require(amount > 0, "!0");

        address borrower = msg.sender;

        // Revert if the borrower is restricted.
        require(!_BORROWER_RESTRICTIONS_[borrower], "Restricted");

        // Get contract available amount and revert if there is not enough to withdraw.
        uint256 totalAvailableForBorrow = getContractBalanceAvailableToBorrow();
        require(
            amount <= totalAvailableForBorrow,
            ">available"
        );

        // Get new net borrow and revert if it is greater than the allocated balance for new borrowing.
        uint256 newBorrowedBalance = _BORROWED_BALANCES_[borrower].add(amount);
        require(
            newBorrowedBalance <= _getAllocatedBalanceForNewBorrowing(borrower),
            ">allocated"
        );

        // Update storage.
        _BORROWED_BALANCES_[borrower] = newBorrowedBalance;
        _TOTAL_BORROWED_BALANCE_ = _TOTAL_BORROWED_BALANCE_.add(amount);

        // Transfer token to the Market maker Proxy contract.
        STAKED_TOKEN.safeTransfer(borrower, amount);

        emit Borrowed(borrower, amount, newBorrowedBalance);
    }

    /**
     * @notice Repay borrowed funds for the specified borrower. Reverts if repay amount exceeds
     *  borrowed amount.
     *
     * @param  borrower  The borrower on whose behalf to make a repayment.
     * @param  amount    The amount to repay.
     */
    function repayBorrow(address borrower, uint256 amount) external nonReentrant {
        require(amount > 0, "!0");

        uint256 oldBorrowedBalance = _BORROWED_BALANCES_[borrower];
        require(amount <= oldBorrowedBalance, ">borrowed");
        uint256 newBorrowedBalance = oldBorrowedBalance.sub(amount);

        // Update storage.
        _BORROWED_BALANCES_[borrower] = newBorrowedBalance;
        _TOTAL_BORROWED_BALANCE_ = _TOTAL_BORROWED_BALANCE_.sub(amount);

        // Transfer token from the sender.
        STAKED_TOKEN.safeTransferFrom(msg.sender, address(this), amount);

        emit RepaidBorrow(borrower, msg.sender, amount, newBorrowedBalance);
    }

    /**
     * @notice Repay a debt amount owed by a borrower.
     *
     * @param  borrower  The borrower whose debt to repay.
     * @param  amount    The amount to repay.
     */
    function repayDebt(address borrower, uint256 amount) external nonReentrant {
        require(amount > 0, "!0");

        uint256 oldDebtAmount = _BORROWER_DEBT_BALANCES_[borrower];
        require(amount <= oldDebtAmount, "Repay > debt");
        uint256 newDebtBalance = oldDebtAmount.sub(amount);

        // Update storage.
        _BORROWER_DEBT_BALANCES_[borrower] = newDebtBalance;
        _TOTAL_BORROWER_DEBT_BALANCE_ = _TOTAL_BORROWER_DEBT_BALANCE_.sub(
            amount
        );
        _TOTAL_DEBT_AVAILABLE_TO_WITHDRAW_ = _TOTAL_DEBT_AVAILABLE_TO_WITHDRAW_
            .add(amount);

        // Transfer token from the sender.
        STAKED_TOKEN.safeTransferFrom(msg.sender, address(this), amount);

        emit RepaidDebt(borrower, msg.sender, amount, newDebtBalance);
    }

    /**
     * @notice Get the max additional amount that the borrower can borrow.
     *
     * @return The max additional amount that the borrower can borrow right now.
     */
    function getBorrowableAmount(address borrower)
        external
        view
        returns (uint256)
    {
        if (
            _BORROWER_RESTRICTIONS_[borrower]
        ) {
            return 0;
        }

        // Get the remaining unused allocation for the borrower.
        uint256 oldBorrowedBalance = _BORROWED_BALANCES_[borrower];
        uint256 borrowerAllocatedBalance = _getAllocatedBalanceForNewBorrowing(
            borrower
        );
        if (borrowerAllocatedBalance <= oldBorrowedBalance) {
            return 0;
        }
        uint256 borrowerRemainingAllocatedBalance = borrowerAllocatedBalance
            .sub(oldBorrowedBalance);

        // Don't allow new borrowing to take out funds that are reserved for debt or inactive balances.
        // Typically, this will not be the limiting factor, but it can be.
        uint256 totalAvailableForBorrow = getContractBalanceAvailableToBorrow();

        return
            MathUpgradeable.min(
                borrowerRemainingAllocatedBalance,
                totalAvailableForBorrow
            );
    }

    // ============ Public Functions ============

    /**
     * @notice Get the funds currently available in the contract for borrowing.
     *
     * @return The amount of non-debt, non-inactive funds in the contract.
     */
    function getContractBalanceAvailableToBorrow()
        public
        view
        returns (uint256)
    {
        uint256 availableStake = getContractBalanceAvailableToWithdraw();
        uint256 inactiveBalance = getTotalInactiveBalanceCurrentEpoch();
        // Note: The funds available to withdraw may be less than the inactive balance.
        if (availableStake <= inactiveBalance) {
            return 0;
        }
        return availableStake.sub(inactiveBalance);
    }
}