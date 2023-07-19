// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.13;

import "../loans/IBaseLoan.sol";

/// @title Interface for  Loan Offer Validators.
/// @author Florida St
/// @notice Verify the given `_offer` is valid for `_tokenId` and `_validatorData`.
interface IBaseOfferValidator {
    /// @notice Validate a loan offer.
    function validateOffer(
        IBaseLoan.LoanOffer calldata _offer,
        uint256 _tokenId,
        bytes calldata _validatorData
    ) external;
}