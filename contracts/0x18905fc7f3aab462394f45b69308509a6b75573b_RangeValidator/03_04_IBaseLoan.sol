// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.13;

import "../../interfaces/ILoanLiquidator.sol";

/// @title Interface for Loans.
/// @author Florida St
/// @notice Basic Loan
interface IBaseLoan {
    /// @notice Minimum improvement (in BPS) required for a strict improvement.
    /// @param principalAmount Minimum delta of principal amount.
    /// @param interest Minimum delta of interest.
    /// @param duration Minimum delta of duration.
    struct ImprovementMinimum {
        uint256 principalAmount;
        uint256 interest;
        uint256 duration;
    }

    /// @notice Arbitrary contract to validate offers implementing `ISingleSourceLoanOfferValidator`.
    /// @param validator Address of the validator contract.
    /// @param arguments Arguments to pass to the validator.
    struct OfferValidator {
        address validator;
        bytes arguments;
    }

    /// @notice Borrowers receive offers that are then validated.
    /// @dev Setting the nftCollateralTokenId to 0 triggers validation through `validators`.
    /// @param offerId Offer ID. Used for canceling/setting as executed.
    /// @param lender Lender of the offer.
    /// @param fee Origination fee.
    /// @param borrower Borrower of the offer. Can be set to 0 (any borrower).
    /// @param capacity Capacity of the offer.
    /// @param signer Signer of the offer.
    /// @param requiresLiquidation Whether the loan requires liquidation.
    /// @param nftCollateralAddress Address of the NFT collateral.
    /// @param nftCollateralTokenId NFT collateral token ID.
    /// @param principalAddress Address of the principal.
    /// @param principalAmount Principal amount of the loan.
    /// @param aprBps APR in BPS.
    /// @param expirationTime Expiration time of the offer.
    /// @param duration Duration of the loan in seconds.
    /// @param validators Arbitrary contract to validate offers implementing `ISingleSourceLoanOfferValidator`.
    struct LoanOffer {
        uint256 offerId;
        address lender;
        uint256 fee;
        address borrower;
        uint256 capacity;
        address signer;
        bool requiresLiquidation;
        address nftCollateralAddress;
        uint256 nftCollateralTokenId;
        address principalAddress;
        uint256 principalAmount;
        uint256 aprBps;
        uint256 expirationTime;
        uint256 duration;
        OfferValidator[] validators;
    }

    /// @notice Recipient address and fraction of gains charged by the protocol.
    struct ProtocolFee {
        address recipient;
        uint256 fraction;
    }

    /// @notice Total number of loans issued by this contract.
    function getTotalLoansIssued() external view returns (uint256);

    /// @notice Called by the liquidator for accounting purposes.
    ///         If the lender is a vault, we call the onLoanRepaid hook with
    ///         the amount collected by the auction.
    /// @param _collateralAddress The address of the nft collection.
    /// @param _collateralTokenId The id of the nft.
    /// @param _loanId The id of the loan.
    /// @param _repayment The highest bid of the auction.
    /// @param _loan The loan object.
    function loanLiquidated(
        address _collateralAddress,
        uint256 _collateralTokenId,
        uint256 _loanId,
        uint256 _repayment,
        bytes calldata _loan
    ) external;

    /// @notice Each lender has unique offerIds.
    /// @param _lender Lender of the offer.
    /// @param _offerId Offer ID.
    function cancelOffer(address _lender, uint256 _offerId) external;

    /// @notice Cancel multiple offers.
    /// @param _lender Lender of the offer.
    /// @param _offerIds Offer IDs.
    function cancelOffers(
        address _lender,
        uint256[] calldata _offerIds
    ) external;

    /// @notice Cancell all offers with offerId < _minOfferId
    /// @param _lender Lender of the offer.
    /// @param _minOfferId Minimum offer ID.
    function cancelAllOffers(address _lender, uint256 _minOfferId) external;

    /// @notice Cancel renegotiation offer. Similar to offers.
    /// @param _lender Lender of the renegotiation offer.
    /// @param _renegotiationId Renegotiation offer ID.
    function cancelRenegotiationOffer(
        address _lender,
        uint256 _renegotiationId
    ) external;

    /// @notice Cancel multiple renegotiation offers.
    /// @param _lender Lender of the renegotiation offers.
    /// @param _renegotiationIds Renegotiation offer IDs.
    function cancelRenegotiationOffers(
        address _lender,
        uint256[] calldata _renegotiationIds
    ) external;

    /// @notice Cancell all renegotiation offers with renegotiationId < _minRenegotiationId
    /// @param _lender Lender of the renegotiation offers.
    function cancelAllRenegotiationOffers(
        address _lender,
        uint256 _minRenegotiationId
    ) external;

    /// @notice Approve a wallet to sign offers for msg.sender.
    /// @param _signer Signer address.
    function approveSigner(address _signer) external;

    /// @notice Get approved signer for a given lender.
    /// @param _lender Lender address.
    function getApprovedSigner(address _lender) external returns (address);

    /// @return Protocol fee.
    function getProtocolFee() external view returns (ProtocolFee memory);

    /// @return Pending protocol fee.
    function getPendingProtocolFee() external view returns (ProtocolFee memory);

    /// @return Time when the protocol fee was set to be changed.
    function getPendingProtocolFeeSetTime() external view returns (uint256);

    /// @notice Kicks off the process to update the protocol fee.
    /// @param _newProtocolFee New protocol fee.
    function updateProtocolFee(ProtocolFee calldata _newProtocolFee) external;

    /// @notice Set the protocol fee if enough notice has been given.
    function setProtocolFee() external;

    /// @return Liquidator contract address
    function getLiquidator() external returns (address);

    /// @notice Updates the liquidation contract.
    /// @param loanLiquidator New liquidation contract.
    function updateLiquidationContract(ILoanLiquidator loanLiquidator) external;

    /// @notice Updates the auction duration for liquidations.
    /// @param _newDuration New auction duration.
    function updateLiquidationAuctionDuration(uint48 _newDuration) external;

    /// @return Returns the auction's duration for liquidations.
    function getLiquidationAuctionDuration() external returns (uint48);

    /// @notice Add a whitelisted callback contract.
    /// @param _contract Address of the contract.
    function addWhitelistedCallbackContract(address _contract) external;

    /// @notice Remove a whitelisted callback contract.
    /// @param _contract Address of the contract.
    function removeWhitelistedCallbackContract(address _contract) external;

    /// @return Whether a callback contract is whitelisted
    function isWhitelistedCallbackContract(
        address _contract
    ) external view returns (bool);
}