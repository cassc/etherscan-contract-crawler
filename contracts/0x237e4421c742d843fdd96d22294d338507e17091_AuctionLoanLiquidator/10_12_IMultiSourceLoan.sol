// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.13;

import "./IBaseLoan.sol";

interface IMultiSourceLoan {
    struct Source {
        uint256 loanId;
        address lender;
        uint256 principalAmount;
        uint256 accruedInterest;
        uint256 startTime;
        uint256 aprBps;
    }

    /// @dev Principal Amount is equal to the sum of all sources principalAmount.
    /// We keep it for caching purposes. Since we are not saving this on chain but the hash,
    /// it is not a problem from a gas perspective.
    struct Loan {
        address borrower;
        uint256 nftCollateralTokenId;
        address nftCollateralAddress;
        address principalAddress;
        uint256 principalAmount;
        uint256 startTime;
        uint256 duration;
        Source[] source;
    }

    struct RenegotiationOffer {
        uint256 renegotiationId;
        uint256 loanId;
        address lender;
        uint256 fee;
        address signer;
        uint256[] targetPrincipal;
        uint256 principalAmount;
        uint256 aprBps;
        uint256 expirationTime;
        uint256 duration;
        bool strictImprovement;
    }

    /// @notice Call by the borrower when emiting a new loan.
    /// @param _loanOffer Loan offer.
    /// @param _tokenId NFT collateral token ID.
    /// @param _lenderOfferSignature Signature of the offer (signed by lender/signer).
    /// @param _withCallback Whether to call the afterPrincipalTransfer callback
    /// @return loanId Loan ID.
    /// @return loan Loan.
    function emitLoan(
        IBaseLoan.LoanOffer calldata _loanOffer,
        uint256 _tokenId,
        bytes calldata _lenderOfferSignature,
        bool _withCallback
    ) external returns (uint256, Loan memory);

    /// @notice Refinance whole loan (leaving just one source).
    /// @param _renegotiationOffer Offer to refinance a loan.
    /// @param _loan Current loan.
    /// @param _renegotiationOfferSignature Signature of the offer.
    /// @return New Loan Id, New Loan.
    function refinanceFull(
        RenegotiationOffer calldata _renegotiationOffer,
        Loan memory _loan,
        bytes calldata _renegotiationOfferSignature
    ) external returns (uint256, Loan memory);

    /// @notice Refinance a loan partially. It can only be called by the new lender
    /// or respective signer (they are always a strict improvement on apr).
    /// @param _renegotiationOffer Offer to refinance a loan partially.
    /// @param _loan Current loan.
    /// @return New Loan Id, New Loan.
    function refinancePartial(
        RenegotiationOffer calldata _renegotiationOffer,
        Loan memory _loan
    ) external returns (uint256, Loan memory);

    /// @notice Refinance multiple loans partially in one transaction.
    /// @dev Length of _renegotiationOffer and _loan must be the same since they map 1:1.
    /// Note that if for some reasno, the same loan is targeted multiple times (no reason
    /// why someone would do this), the loan sources would change from one iteration to another.
    /// @param _renegotiationOffer Refinance offers.
    /// @param _loan Loans.
    /// @return loanId NEw Loan Ids
    /// @return loan New Loans.
    function refinancePartialBatch(
        RenegotiationOffer[] calldata _renegotiationOffer,
        Loan[] memory _loan
    ) external returns (uint256[] memory loanId, Loan[] memory loan);

    /// @notice Repay loan. Only the borrower (defined in the loan struct) can repay.
    ///         Interest is calculated pro-rata based on time. Lender is defined by nft ownership.
    /// @param _collateralTo Address to send the collateral to.
    /// @param _loanId Loan ID.
    /// @param _loan Loan.
    /// @param _withCallback Whether to call the afterNFTTransfer callback
    function repayLoan(
        address _collateralTo,
        uint256 _loanId,
        Loan calldata _loan,
        bool _withCallback
    ) external;

    /// @notice Call when a loan is past its due date.
    /// @param _loanId Loan ID.
    /// @param _loan Loan.
    function liquidateLoan(uint256 _loanId, Loan calldata _loan) external;

    /// @return Max sources per loan.
    function getMaxSources() external view returns (uint8);

    /// @notice Update the maximum number of sources per loan.
    /// @param maxSources Maximum number of sources.
    function setMaxSources(uint8 maxSources) external;
}