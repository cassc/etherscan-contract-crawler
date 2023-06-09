// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.7;

import { IMapleLoanEvents } from "./IMapleLoanEvents.sol";

interface IMapleLoanInitializer is IMapleLoanEvents {

    /**
     *  @dev    Encodes the initialization arguments for a MapleLoan.
     *  @param  borrower_           The address of the borrower.
     *  @param  lender_             The address of the lender.
     *  @param  fundsAsset_         The address of the lent asset.
     *  @param  principalRequested_ The amount of principal requested.
     *  @param  termDetails_        Array of loan parameters:
     *                                  [0]: gracePeriod,
     *                                  [1]: noticePeriod,
     *                                  [2]: paymentInterval
     *  @param  rates_              Array of rate parameters:
     *                                  [0]: delegateServiceFeeRate,
     *                                  [1]: interestRate,
     *                                  [2]: lateFeeRate,
     *                                  [3]: lateInterestPremiumRate
     *  @return encodedArguments_  The encoded arguments for initializing a loan.
     */
    function encodeArguments(
        address          borrower_,
        address          lender_,
        address          fundsAsset_,
        uint256          principalRequested_,
        uint32[3] memory termDetails_,
        uint64[4] memory rates_
    ) external pure returns (bytes memory encodedArguments_);

    /**
     *  @dev    Decodes the initialization arguments for a MapleLoan.
     *  @param  encodedArguments_   The encoded arguments for initializing a loan.
     *  @return borrower_           The address of the borrower.
     *  @return lender_             The address of the lender.
     *  @return fundsAsset_         The address of the lent asset.
     *  @return principalRequested_ The amount of principal requested.
     *  @return termDetails_        Array of loan parameters:
     *                                  [0]: gracePeriod,
     *                                  [1]: noticePeriod,
     *                                  [2]: paymentInterval
     *  @return rates_              Array of rate parameters:
     *                                  [0]: delegateServiceFeeRate,
     *                                  [1]: interestRate,
     *                                  [2]: lateFeeRate,
     *                                  [3]: lateInterestPremiumRate
     */
    function decodeArguments(bytes calldata encodedArguments_) external pure
        returns (
            address          borrower_,
            address          lender_,
            address          fundsAsset_,
            uint256          principalRequested_,
            uint32[3] memory termDetails_,
            uint64[4] memory rates_
        );

}