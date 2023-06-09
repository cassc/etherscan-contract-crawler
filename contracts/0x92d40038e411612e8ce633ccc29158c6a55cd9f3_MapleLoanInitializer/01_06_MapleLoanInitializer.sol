// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.7;

import { IMapleLoanInitializer } from "./interfaces/IMapleLoanInitializer.sol";

import { IGlobalsLike, ILenderLike, IMapleProxyFactoryLike } from "./interfaces/Interfaces.sol";

import { MapleLoanStorage } from "./MapleLoanStorage.sol";

contract MapleLoanInitializer is IMapleLoanInitializer, MapleLoanStorage {

    function encodeArguments(
        address          borrower_,
        address          lender_,
        address          fundsAsset_,
        uint256          principalRequested_,
        uint32[3] memory termDetails_,
        uint64[4] memory rates_
    ) external pure override returns (bytes memory encodedArguments_) {
        return abi.encode(borrower_, lender_, fundsAsset_, principalRequested_, termDetails_, rates_);
    }

    function decodeArguments(bytes calldata encodedArguments_)
        public pure override returns (
            address          borrower_,
            address          lender_,
            address          fundsAsset_,
            uint256          principalRequested_,
            uint32[3] memory termDetails_,
            uint64[4] memory rates_
        )
    {
        (
            borrower_,
            lender_,
            fundsAsset_,
            principalRequested_,
            termDetails_,
            rates_
        ) = abi.decode(encodedArguments_, (address, address, address, uint256, uint32[3], uint64[4]));
    }

    fallback() external {
        (
            address          borrower_,
            address          lender_,
            address          fundsAsset_,
            uint256          principalRequested_,
            uint32[3] memory termDetails_,
            uint64[4] memory rates_
        ) = decodeArguments(msg.data);

        _initialize(borrower_, lender_, fundsAsset_, principalRequested_, termDetails_, rates_);
    }

    function _initialize(
        address          borrower_,
        address          lender_,
        address          fundsAsset_,
        uint256          principalRequested_,
        uint32[3] memory termDetails_,
        uint64[4] memory rates_
    )
        internal
    {
        // Principal requested needs to be non-zero (see `_getCollateralRequiredFor` math).
	    require(principalRequested_ != 0, "MLI:I:INVALID_PRINCIPAL");

        // Payment interval and notice period to be non-zero.
        require(termDetails_[1] != 0, "MLI:I:INVALID_NOTICE_PERIOD");
        require(termDetails_[2] != 0, "MLI:I:INVALID_PAYMENT_INTERVAL");

        address globals_ = IMapleProxyFactoryLike(msg.sender).mapleGlobals();

        require((borrower = borrower_) != address(0),            "MLI:I:ZERO_BORROWER");
        require(IGlobalsLike(globals_).isBorrower(borrower_),    "MLI:I:INVALID_BORROWER");
        require(IGlobalsLike(globals_).isPoolAsset(fundsAsset_), "MLI:I:INVALID_FUNDS_ASSET");

        require((lender = lender_) != address(0), "MLI:I:ZERO_LENDER");

        address loanManagerFactory_ = ILenderLike(lender_).factory();

        require(ILenderLike(lender_).fundsAsset() == fundsAsset_,                                    "MLI:I:DIFFERENT_ASSET");
        require(IGlobalsLike(globals_).isInstanceOf("OT_LOAN_MANAGER_FACTORY", loanManagerFactory_), "MLI:I:INVALID_FACTORY");
        require(IMapleProxyFactoryLike(loanManagerFactory_).isInstance(lender_),                     "MLI:I:INVALID_INSTANCE");

        fundsAsset = fundsAsset_;

        principal = principalRequested_;

        gracePeriod     = termDetails_[0];
        noticePeriod    = termDetails_[1];
        paymentInterval = termDetails_[2];

        delegateServiceFeeRate  = rates_[0];
        interestRate            = rates_[1];
        lateFeeRate             = rates_[2];
        lateInterestPremiumRate = rates_[3];

        platformServiceFeeRate = uint64(IGlobalsLike(globals_).platformServiceFeeRate(ILenderLike(lender_).poolManager()));

        emit Initialized(borrower_, lender_, fundsAsset_, principalRequested_, termDetails_, rates_);
    }

}