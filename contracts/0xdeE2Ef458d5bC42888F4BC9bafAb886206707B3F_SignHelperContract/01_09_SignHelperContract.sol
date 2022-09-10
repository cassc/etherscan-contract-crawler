// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "./SignHelper.sol";

contract SignHelperContract {
    function checkBorrowerSignatureValidity(
        LoanStructures.ListingTerms memory _listingTerms,
        LoanStructures.Signature memory _signature,
        address _loanContract
    ) external view returns (bool) {
        return SignHelper.checkBorrowerSignatureValidity(_listingTerms, _signature, _loanContract);
    }

    function checkBorrowerSignatureValidityBundle(
        LoanStructures.ListingTerms memory _listingTerms,
        IPackBuilder.BundleElements memory _bundleElements,
        LoanStructures.Signature memory _signature,
        address _loanContract
    ) external view returns (bool) {
        return
            SignHelper.checkBorrowerSignatureValidityBundle(_listingTerms, _bundleElements, _signature, _loanContract);
    }

    function checkLenderSignatureValidity(
        LoanStructures.Offer memory _offer,
        LoanStructures.Signature memory _signature,
        address _loanContract
    ) external view returns (bool) {
        return SignHelper.checkLenderSignatureValidity(_offer, _signature, _loanContract);
    }

    function checkLenderSignatureValidityBundle(
        LoanStructures.Offer memory _offer,
        IPackBuilder.BundleElements memory _bundleElements,
        LoanStructures.Signature memory _signature,
        address _loanContract
    ) external view returns (bool) {
        return SignHelper.checkLenderSignatureValidityBundle(_offer, _bundleElements, _signature, _loanContract);
    }

    function checkLenderRenegotiationSignatureValidity(
        uint256 _loanId,
        uint32 _newLoanDuration,
        uint256 _newMaximumRepaymentAmount,
        uint256 _renegotiationFee,
        LoanStructures.Signature memory _signature,
        address _loanContract
    ) external view returns (bool) {
        return
            SignHelper.checkLenderRenegotiationSignatureValidity(
                _loanId,
                _newLoanDuration,
                _newMaximumRepaymentAmount,
                _renegotiationFee,
                _signature,
                _loanContract
            );
    }
}