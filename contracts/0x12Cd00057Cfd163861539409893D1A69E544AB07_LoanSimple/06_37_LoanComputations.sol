// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "./ILoanCommon.sol";
import "./LoanStructures.sol";
import "../../interfaces/ILoanManager.sol";
import "../../utils/KeysMapping.sol";
import "../../interfaces/IDispatcher.sol";
import "../../interfaces/IAllowedPartners.sol";
import "../../interfaces/IAllowedERC20s.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

library LoanComputations {
    uint16 private constant HUNDRED_PERCENT = 10000;

    function validatePayback(uint32 _loanId, IDispatcher _hub) external view {
        checkLoanIdValidity(_loanId, _hub);
        // Sanity check that payBackLoan() and liquidateExpiredLoan() have never been called on this loanId.
        // Depending on how the rest of the code turns out, this check may be unnecessary.
        require(!ILoanCommon(address(this)).loanRepaidOrLiquidated(_loanId), "Loan already repaid/liquidated");

        // Fetch loan details from storage, but store them in memory for the sake of saving gas.
        (, , , , uint32 loanDuration, , , , uint64 loanStartTime, , ) = ILoanCommon(address(this)).loanIdToLoan(
            _loanId
        );

        // When a loan exceeds the loan term, it is expired. At this stage the Lender can call Liquidate Loan to resolve
        // the loan.
        require(block.timestamp <= (uint256(loanStartTime) + uint256(loanDuration)), "Loan is expired");
    }

    function checkLoanIdValidity(uint32 _loanId, IDispatcher _hub) public view {
        require(
            ILoanManager(_hub.getContract(ILoanCommon(address(this)).LOAN_COORDINATOR())).isValidLoanId(
                _loanId,
                address(this)
            ),
            "invalid loanId"
        );
    }

    function getRevenueSharePercent(address _revenueSharePartner, IDispatcher _hub) external view returns (uint16) {
        // return soon if no partner is set to avoid a public call
        if (_revenueSharePartner == address(0)) {
            return 0;
        }

        uint16 revenueSharePercent = IAllowedPartners(_hub.getContract(KeysMapping.PERMITTED_PARTNERS))
        .getPartnerPermit(_revenueSharePartner);

        return revenueSharePercent;
    }

    function validateRenegotiation(
        LoanStructures.LoanTerms memory _loan,
        uint32 _loanId,
        uint32 _newLoanDuration,
        uint256 _newMaximumRepaymentAmount,
        uint256 _lenderNonce,
        IDispatcher _hub
    ) external view returns (address, address) {
        checkLoanIdValidity(_loanId, _hub);
        ILoanManager loanCoordinator = ILoanManager(
            _hub.getContract(ILoanCommon(address(this)).LOAN_COORDINATOR())
        );
        uint256 notesNftId = loanCoordinator.getLoanData(_loanId).notesNftId;

        address borrower;

        if (_loan.borrower != address(0)) {
            borrower = _loan.borrower;
        } else {
            borrower = IERC721(loanCoordinator.obligationReceiptToken()).ownerOf(notesNftId);
        }

        require(msg.sender == borrower, "Only borrower can initiate");
        require(block.timestamp <= (uint256(_loan.loanStartTime) + _newLoanDuration), "New duration already expired");
        require(
            uint256(_newLoanDuration) <= ILoanCommon(address(this)).maximumLoanDuration(),
            "New duration exceeds maximum loan duration"
        );
        require(!ILoanCommon(address(this)).loanRepaidOrLiquidated(_loanId), "Loan already repaid/liquidated");
        require(
            _newMaximumRepaymentAmount >= _loan.loanPrincipalAmount,
            "Negative interest rate loans are not allowed."
        );

        // Fetch current owner of loan promissory note.
        address lender = IERC721(loanCoordinator.promissoryNoteToken()).ownerOf(notesNftId);

        require(
            !ILoanCommon(address(this)).hasNonceBeenUsedForUser(lender, _lenderNonce),
            "Lender nonce invalid"
        );

        return (borrower, lender);
    }

    function bindingTermsSanityChecks(LoanStructures.ListingTerms memory _listingTerms, LoanStructures.Offer memory _offer)
        external
        pure
    {
        // offer vs listing validations
        require(_offer.loanERC20Denomination == _listingTerms.loanERC20Denomination, "Invalid loanERC20Denomination");
        require(
            _offer.loanPrincipalAmount >= _listingTerms.minLoanPrincipalAmount &&
                _offer.loanPrincipalAmount <= _listingTerms.maxLoanPrincipalAmount,
            "Invalid loanPrincipalAmount"
        );
        uint256 maxRepaymentLimit = _offer.loanPrincipalAmount +
            (_offer.loanPrincipalAmount * _listingTerms.maxInterestRateForDurationInBasisPoints) /
            HUNDRED_PERCENT;
        require(_offer.maximumRepaymentAmount <= maxRepaymentLimit, "maxInterestRateForDurationInBasisPoints violated");

        require(
            _offer.loanDuration >= _listingTerms.minLoanDuration &&
                _offer.loanDuration <= _listingTerms.maxLoanDuration,
            "Invalid loanDuration"
        );
    }

    function getRevenueShare(uint256 _adminFee, uint256 _revenueShareInBasisPoints)
        external
        pure
        returns (uint256)
    {
        return (_adminFee * _revenueShareInBasisPoints) / HUNDRED_PERCENT;
    }

    function getAdminFee(uint256 _interestDue, uint256 _adminFeeInBasisPoints) external pure returns (uint256) {
        return (_interestDue * _adminFeeInBasisPoints) / HUNDRED_PERCENT;
    }

    function getReferralFee(
        uint256 _loanPrincipalAmount,
        uint256 _referralFeeInBasisPoints,
        address _referrer
    ) external pure returns (uint256) {
        if (_referralFeeInBasisPoints == 0 || _referrer == address(0)) {
            return 0;
        }
        return (_loanPrincipalAmount * _referralFeeInBasisPoints) / HUNDRED_PERCENT;
    }
}