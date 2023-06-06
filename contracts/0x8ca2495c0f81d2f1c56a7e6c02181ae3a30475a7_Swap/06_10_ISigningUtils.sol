// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;

import "../../../utils/DataTypes.sol";
import "../../../utils/LoanDataTypes.sol";

interface ISigningUtils {
    /// -----------------------------------------------------------------------
    /// Errors
    /// -----------------------------------------------------------------------

    enum SigningUtilsErrorCodes {
        INVALID_LISTING_SIGNATURE,
        INVALID_SWAP_OFFER_SIGNATURE,
        INVALID_COLLECTION_SWAP_OFFER_SIGNATURE,
        INVALID_RESERVE_OFFER_SIGNATURE,
        INVALID_COLLECTION_RESERVE_OFFER_SIGNATURE,
        INVALID_LOAN_OFFER_SIGNATURE,
        INVALID_COLLECTION_LOAN_OFFER_SIGNATURE,
        INVALID_UPDATE_LOAN_OFFER_SIGNATURE
    }

    error SigningUtilsError(SigningUtilsErrorCodes code);

    /// -----------------------------------------------------------------------
    /// Signature Verification Actions
    /// -----------------------------------------------------------------------

    /// @dev Check the signature if the listing info is valid or not.
    /// @param _listing Listing info
    /// @param signature Listing signature
    function verifyListingSignature(
        Listing calldata _listing,
        bytes calldata signature
    ) external view;

    /// @dev Check the signature if the swap offer is valid or not.
    /// @param offer Offer info
    /// @param signature Offer signature
    function verifySwapOfferSignature(
        SwapOffer calldata offer,
        bytes calldata signature
    ) external view;

    /// @dev Check the signature if the collection offer is valid or not.
    /// @param offer Offer info
    /// @param signature Offer signature
    function verifyCollectionSwapOfferSignature(
        CollectionSwapOffer calldata offer,
        bytes calldata signature
    ) external view;

    /// @dev Check the signature if the reserve offer is valid or not.
    /// @param offer Reserve offer info
    /// @param signature Reserve offer signature
    function verifyReserveOfferSignature(
        ReserveOffer calldata offer,
        bytes calldata signature
    ) external view;

    /// @dev Check the signature if the collection reserve offer is valid or not.
    /// @param offer Reserve offer info
    /// @param signature Reserve offer signature
    function verifyCollectionReserveOfferSignature(
        CollectionReserveOffer calldata offer,
        bytes calldata signature
    ) external view;

    /// @dev Check the signature if the loan offer is valid or not.
    /// @param offer Loan offer info
    /// @param signature Loan offer signature
    function verifyLoanOfferSignature(
        LoanOffer calldata offer,
        bytes memory signature
    ) external view;

    /// @dev Check the signature if the collection loan offer is valid or not.
    /// @param offer Collection loan offer info
    /// @param signature Collection loan offer signature
    function verifyCollectionLoanOfferSignature(
        CollectionLoanOffer calldata offer,
        bytes memory signature
    ) external view;

    /// @dev Check the signature if the update loan offer is valid or not.
    /// @param offer Update loan offer info
    /// @param signature Update loan offer signature
    function verifyUpdateLoanSignature(
        LoanUpdateOffer calldata offer,
        bytes memory signature
    ) external view;
}