// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.7;

import { IMapleLoanInitializer } from "./interfaces/IMapleLoanInitializer.sol";
import { IMapleLoanFeeManager }  from "./interfaces/IMapleLoanFeeManager.sol";

import { IGlobalsLike, ILenderLike, IMapleProxyFactoryLike } from "./interfaces/Interfaces.sol";

import { MapleLoanStorage } from "./MapleLoanStorage.sol";

contract MapleLoanInitializer is IMapleLoanInitializer, MapleLoanStorage {

    function encodeArguments(
        address           borrower_,
        address           lender_,
        address           feeManager_,
        address[2] memory assets_,
        uint256[3] memory termDetails_,
        uint256[3] memory amounts_,
        uint256[4] memory rates_,
        uint256[2] memory fees_
    ) external pure override returns (bytes memory encodedArguments_) {
        return abi.encode(borrower_, lender_, feeManager_, assets_, termDetails_, amounts_, rates_, fees_);
    }

    function decodeArguments(bytes calldata encodedArguments_)
        public pure override returns (
            address           borrower_,
            address           lender_,
            address           feeManager_,
            address[2] memory assets_,
            uint256[3] memory termDetails_,
            uint256[3] memory amounts_,
            uint256[4] memory rates_,
            uint256[2] memory fees_
        )
    {
        (
            borrower_,
            lender_,
            feeManager_,
            assets_,
            termDetails_,
            amounts_,
            rates_,
            fees_
        ) = abi.decode(encodedArguments_, (address, address, address, address[2], uint256[3], uint256[3], uint256[4], uint256[2]));
    }

    fallback() external {
        (
            address           borrower_,
            address           lender_,
            address           feeManager_,
            address[2] memory assets_,
            uint256[3] memory termDetails_,
            uint256[3] memory amounts_,
            uint256[4] memory rates_,
            uint256[2] memory fees_
        ) = decodeArguments(msg.data);

        _initialize(borrower_, lender_, feeManager_, assets_, termDetails_, amounts_, rates_, fees_);

        emit Initialized(borrower_, lender_, feeManager_, assets_, termDetails_, amounts_, rates_, fees_);
    }

    /**
     *  @dev   Initializes the loan.
     *  @param borrower_    The address of the borrower.
     *  @param feeManager_  The address of the entity responsible for calculating fees
     *  @param assets_      Array of asset addresses.
     *                       [0]: collateralAsset,
     *                       [1]: fundsAsset
     *  @param termDetails_ Array of loan parameters:
     *                       [0]: gracePeriod,
     *                       [1]: paymentInterval,
     *                       [2]: payments
     *  @param amounts_     Requested amounts:
     *                       [0]: collateralRequired,
     *                       [1]: principalRequested,
     *                       [2]: endingPrincipal
     *  @param rates_       Rates parameters:
     *                       [0]: interestRate,
     *                       [1]: closingFeeRate,
     *                       [2]: lateFeeRate,
     *                       [3]: lateInterestPremiumRate,
     *  @param fees_        Array of fees:
     *                       [0]: delegateOriginationFee,
     *                       [1]: delegateServiceFee
     */
    function _initialize(
        address           borrower_,
        address           lender_,
        address           feeManager_,
        address[2] memory assets_,
        uint256[3] memory termDetails_,
        uint256[3] memory amounts_,
        uint256[4] memory rates_,
        uint256[2] memory fees_
    )
        internal
    {
        // Principal requested needs to be non-zero (see `_getCollateralRequiredFor` math).
        require(amounts_[1] > uint256(0), "MLI:I:INVALID_PRINCIPAL");

        // Ending principal needs to be less than or equal to principal requested.
        require(amounts_[2] <= amounts_[1], "MLI:I:INVALID_ENDING_PRINCIPAL");

        // Payment interval and payments remaining need to be non-zero.
        require(termDetails_[0] >= 12 hours, "MLI:I:INVALID_GRACE_PERIOD");
        require(termDetails_[1] > 0,         "MLI:I:INVALID_PAYMENT_INTERVAL");
        require(termDetails_[2] > 0,         "MLI:I:INVALID_PAYMENTS_REMAINING");

        uint256 maxOriginationFee_ = amounts_[1] * 0.025e6 / 1e6;  // 2.5% of principal

        require(fees_[0] <= maxOriginationFee_, "MLI:I:INVALID_ORIGINATION_FEE");

        IGlobalsLike globals_ = IGlobalsLike(IMapleProxyFactoryLike(msg.sender).mapleGlobals());

        require((_borrower = borrower_) != address(0),  "MLI:I:ZERO_BORROWER");
        require(globals_.isBorrower(borrower_),         "MLI:I:INVALID_BORROWER");
        require(globals_.isPoolAsset(assets_[1]),       "MLI:I:INVALID_FUNDS_ASSET");
        require(globals_.isCollateralAsset(assets_[0]), "MLI:I:INVALID_COLLATERAL_ASSET");

        require((_lender = lender_) != address(0), "MLI:I:ZERO_LENDER");

        address loanManagerFactory_ = ILenderLike(lender_).factory();

        require(ILenderLike(lender_).fundsAsset() == assets_[1],                       "MLI:I:DIFFERENT_FUNDS_ASSET");
        require(globals_.isInstanceOf("FT_LOAN_MANAGER_FACTORY", loanManagerFactory_), "MLI:I:INVALID_FACTORY");
        require(IMapleProxyFactoryLike(loanManagerFactory_).isInstance(lender_),       "MLI:I:INVALID_INSTANCE");

        require((_feeManager = feeManager_) != address(0),         "MLI:I:INVALID_MANAGER");
        require(globals_.isInstanceOf("FEE_MANAGER", feeManager_), "MLI:I:INVALID_FEE_MANAGER");

        _collateralAsset = assets_[0];
        _fundsAsset      = assets_[1];

        _gracePeriod       = termDetails_[0];
        _paymentInterval   = termDetails_[1];
        _paymentsRemaining = termDetails_[2];

        _collateralRequired = amounts_[0];
        _principalRequested = amounts_[1];
        _endingPrincipal    = amounts_[2];

        _interestRate            = rates_[0];
        _closingRate             = rates_[1];
        _lateFeeRate             = rates_[2];
        _lateInterestPremiumRate = rates_[3];

        // Set fees for the loan.
        IMapleLoanFeeManager(feeManager_).updateDelegateFeeTerms(fees_[0], fees_[1]);
    }

}