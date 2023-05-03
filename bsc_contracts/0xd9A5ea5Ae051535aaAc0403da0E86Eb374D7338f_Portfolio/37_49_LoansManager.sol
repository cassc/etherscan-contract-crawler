// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.18;

import { IERC20 } from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import { IERC721 } from "openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";
import { IERC721Receiver } from "openzeppelin-contracts/contracts/token/ERC721/IERC721Receiver.sol";
import { ICurrencyConverter } from "./interfaces/ICurrencyConverter.sol";
import { AddLoanParams, ILoansManager } from "./interfaces/ILoansManager.sol";
import { IFixedInterestBulletLoans, FixedInterestBulletLoanStatus } from "./interfaces/IFixedInterestBulletLoans.sol";
import { SafeERC20 } from "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import { MathUtils } from "src/libraries/MathUtils.sol";
import { TokenBalanceTrackerUpgradeable } from "src/TokenBalanceTrackerUpgradeable.sol";
import { Initializable } from "openzeppelin-contracts-upgradeable/contracts/proxy/utils/Initializable.sol";

abstract contract LoansManager is ILoansManager, IERC721Receiver, Initializable, TokenBalanceTrackerUpgradeable {
    using SafeERC20 for IERC20;

    IFixedInterestBulletLoans public fixedInterestBulletLoans;
    IERC20 public asset;

    uint256[] public activeLoanIds;
    mapping(uint256 => bool) public issuedLoanIds;

    function __LoanManager_init(
        IFixedInterestBulletLoans _fixedInterestBulletLoans,
        IERC20 _asset
    )
        internal
        onlyInitializing
    {
        fixedInterestBulletLoans = _fixedInterestBulletLoans;
        asset = _asset;
    }

    function _transferAsset(address to, uint256 amount) internal {
        _decreaseTokenBalance(amount);
        asset.safeTransfer(to, amount);
    }

    function _transferAssetFrom(address from, address to, uint256 amount) internal {
        if (to == address(this)) {
            _increaseTokenBalance(amount);
        }

        if (from == address(this)) {
            _decreaseTokenBalance(amount);
        }

        asset.safeTransferFrom(from, to, amount);
    }

    function _addLoan(AddLoanParams calldata params) internal returns (uint256 loanId) {
        IFixedInterestBulletLoans.IssueLoanInputs memory newParams = IFixedInterestBulletLoans.IssueLoanInputs({
            krwPrincipal: params.krwPrincipal,
            interestRate: params.interestRate,
            recipient: params.recipient,
            collateral: params.collateral,
            collateralId: params.collateralId,
            duration: params.duration,
            asset: asset
        });

        loanId = fixedInterestBulletLoans.issueLoan(newParams);
        issuedLoanIds[loanId] = true;
        emit LoanAdded(loanId);
        return loanId;
    }

    function _fundLoan(uint256 loanId) internal returns (uint256 principal) {
        if (issuedLoanIds[loanId] != true) {
            revert InvalidLoanId();
        }

        principal = fixedInterestBulletLoans.startLoan(loanId);

        if (_getTokenBalance() < principal) {
            revert InSufficientFund();
        }

        activeLoanIds.push(loanId);

        IFixedInterestBulletLoans.LoanMetadata memory loan = fixedInterestBulletLoans.loanData(loanId);
        // transfer collateral from borrower to contract
        IERC721 collateral = IERC721(loan.collateral);
        collateral.safeTransferFrom(collateral.ownerOf(loan.collateralId), address(this), loan.collateralId);

        // transfer token from contract to recipient
        address recipient = fixedInterestBulletLoans.getRecipient(loanId);
        _transferAsset(recipient, principal);

        emit LoanFunded(loanId);
    }

    function _repayLoan(uint256 loanId) internal returns (uint256 amount) {
        if (issuedLoanIds[loanId] != true) {
            revert InvalidLoanId();
        }
        IFixedInterestBulletLoans.LoanMetadata memory loan = fixedInterestBulletLoans.loanData(loanId);
        amount = fixedInterestBulletLoans.expectedUsdRepayAmount(loanId);
        fixedInterestBulletLoans.repayLoan(loanId, amount);
        _tryToExcludeLoan(loanId);

        // transfer token from borrower to contract
        _transferAssetFrom(msg.sender, address(this), amount);

        // transfer collateral from contract to borrower
        IERC721 collateral = IERC721(loan.collateral);
        collateral.safeTransferFrom(address(this), loan.recipient, loan.collateralId);

        emit LoanRepaid(loanId, amount);
    }

    function _repayDefaultedLoan(uint256 loanId, uint256 usdAmount) internal {
        if (issuedLoanIds[loanId] != true) {
            revert InvalidLoanId();
        }
        IFixedInterestBulletLoans.LoanMetadata memory loan = fixedInterestBulletLoans.loanData(loanId);
        fixedInterestBulletLoans.repayDefaultedLoan(loanId, usdAmount);
        _tryToExcludeLoan(loanId);

        // transfer token from borrower to contract
        _transferAssetFrom(msg.sender, address(this), usdAmount);

        // transfer collateral from contract to borrower
        IERC721 collateral = IERC721(loan.collateral);
        collateral.safeTransferFrom(address(this), loan.recipient, loan.collateralId);

        emit LoanRepaid(loanId, usdAmount);
    }

    function _cancelLoan(uint256 loanId) internal {
        fixedInterestBulletLoans.cancelLoan(loanId);
        emit LoanCanceled(loanId);
    }

    function _markLoanAsDefaulted(uint256 loanId) internal {
        fixedInterestBulletLoans.markLoanAsDefaulted(loanId);
        _tryToExcludeLoan(loanId);
        emit LoanDefaulted(loanId);
    }

    function _tryToExcludeLoan(uint256 loanId) internal {
        FixedInterestBulletLoanStatus loanStatus = fixedInterestBulletLoans.getStatus(loanId);

        // only for repaid, defaulted
        if (loanStatus != FixedInterestBulletLoanStatus.Repaid && loanStatus != FixedInterestBulletLoanStatus.Defaulted)
        {
            return;
        }

        uint256 loansLength = activeLoanIds.length;
        for (uint256 i = 0; i < loansLength; i++) {
            if (activeLoanIds[i] == loanId) {
                if (i < loansLength - 1) {
                    activeLoanIds[i] = activeLoanIds[loansLength - 1];
                }
                activeLoanIds.pop();
                emit ActiveLoanRemoved(loanId, loanStatus);
                return;
            }
        }
    }

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    )
        external
        override
        returns (bytes4)
    {
        return this.onERC721Received.selector;
    }

    // *************** Internal *************** //

    function _calculateOverdueValue() internal view returns (uint256 overdueValue) {
        overdueValue = 0;
        uint256[] memory loans = activeLoanIds;
        for (uint256 i = 0; i < loans.length; i++) {
            if (fixedInterestBulletLoans.isOverdue(loans[i])) {
                overdueValue += fixedInterestBulletLoans.expectedUsdRepayAmount(loans[i]);
            }
        }
    }

    uint256[50] private __gap;
}