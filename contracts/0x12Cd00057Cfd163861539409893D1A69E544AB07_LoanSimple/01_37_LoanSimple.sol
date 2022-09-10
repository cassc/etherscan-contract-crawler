// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "./LoanCommonEssential.sol";
import "../../utils/KeysMapping.sol";

contract LoanSimple is LoanCommonEssential {
    bytes32 public constant LOAN_TYPE = bytes32("DIRECT_LOAN_FIXED_OFFER");

    constructor(
        address _admin,
        address _dispatcher,
        address[] memory _allowedERC20s
    )
        LoanCommonEssential(
            _admin,
            _dispatcher,
            KeysMapping.keyToId("DIRECT_LOAN_COORDINATOR"),
            _allowedERC20s
        )
    {
        // solhint-disable-previous-line no-empty-blocks
    }

    function acceptOffer(
        Offer memory _offer,
        Signature memory _signature,
        BorrowerSettings memory _borrowerSettings
    ) external whenNotPaused nonReentrant {
        address nftWrapper = _getWrapper(_offer.nftCollateralContract);
        _loanSanityChecks(_offer, nftWrapper);
        _loanSanityChecksOffer(_offer);
        _acceptOffer(
            LOAN_TYPE,
            _setupLoanTerms(_offer, nftWrapper),
            _setupLoanExtras(_borrowerSettings.revenueSharePartner, _borrowerSettings.referralFeeInBasisPoints),
            _offer,
            _signature
        );
    }

    function computePayoffAmount(uint32 _loanId) external view override returns (uint256) {
        LoanTerms storage loan = loanIdToLoan[_loanId];
        return loan.maximumRepaymentAmount;
    }

    function _acceptOffer(
        bytes32 _loanType,
        LoanTerms memory _loanTerms,
        LoanExtras memory _loanExtras,
        Offer memory _offer,
        Signature memory _signature
    ) internal {
        require(!_nonceHasBeenUsedForUser[_signature.signer][_signature.nonce], "Lender nonce invalid");

        _nonceHasBeenUsedForUser[_signature.signer][_signature.nonce] = true;

        require(SignHelper.checkLenderSignatureValidity(_offer, _signature), "Lender signature is invalid");

        address bundle = hub.getContract(KeysMapping.LIQUIDOTS_BUNDLER);
        require(_loanTerms.nftCollateralContract != bundle, "Collateral cannot be bundle");

        uint32 loanId = _createLoan(_loanType, _loanTerms, _loanExtras, msg.sender, _signature.signer, _offer.referrer);

        // Emit an event with all relevant details from this transaction.
        emit LoanStarted(loanId, msg.sender, _signature.signer, _loanTerms, _loanExtras);
    }

    function _setupLoanTerms(Offer memory _offer, address _nftWrapper) internal view returns (LoanTerms memory) {
        return
            LoanTerms({
                loanERC20Denomination: _offer.loanERC20Denomination,
                loanPrincipalAmount: _offer.loanPrincipalAmount,
                maximumRepaymentAmount: _offer.maximumRepaymentAmount,
                nftCollateralContract: _offer.nftCollateralContract,
                nftCollateralWrapper: _nftWrapper,
                nftCollateralId: _offer.nftCollateralId,
                loanStartTime: uint64(block.timestamp),
                loanDuration: _offer.loanDuration,
                loanInterestRateForDurationInBasisPoints: uint16(0),
                loanAdminFeeInBasisPoints: _offer.loanAdminFeeInBasisPoints,
                borrower: msg.sender
            });
    }

    function _payoffAndFee(LoanTerms memory _loanTerms)
        internal
        pure
        override
        returns (uint256 adminFee, uint256 payoffAmount)
    {
        // Calculate amounts to send to lender and admins
        uint256 interestDue = _loanTerms.maximumRepaymentAmount - _loanTerms.loanPrincipalAmount;
        adminFee = LoanComputations.getAdminFee(
            interestDue,
            uint256(_loanTerms.loanAdminFeeInBasisPoints)
        );
        payoffAmount = _loanTerms.maximumRepaymentAmount - adminFee;
    }

    function _loanSanityChecksOffer(LoanStructures.Offer memory _offer) internal pure {
        require(
            _offer.maximumRepaymentAmount >= _offer.loanPrincipalAmount,
            "Negative interest rate loans are not allowed."
        );
    }
}