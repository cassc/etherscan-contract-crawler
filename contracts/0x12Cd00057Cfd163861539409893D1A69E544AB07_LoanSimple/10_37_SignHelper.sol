// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "../interfaces/IPackBuilder.sol";
import "../loans/types/LoanStructures.sol";
import "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";

library SignHelper {
    function getChainID() public view returns (uint256) {
        uint256 id;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            id := chainid()
        }
        return id;
    }

    function checkBorrowerSignatureValidity(LoanStructures.ListingTerms memory _listingTerms, LoanStructures.Signature memory _signature)
        external
        view
        returns (bool)
    {
        return checkBorrowerSignatureValidity(_listingTerms, _signature, address(this));
    }

    function checkBorrowerSignatureValidity(
        LoanStructures.ListingTerms memory _listingTerms,
        LoanStructures.Signature memory _signature,
        address _loanContract
    ) public view returns (bool) {
        require(block.timestamp <= _signature.expiry, "Borrower Signature has expired");
        require(_loanContract != address(0), "Loan is zero address");
        if (_signature.signer == address(0)) {
            return false;
        } else {
            bytes32 message = keccak256(
                abi.encodePacked(
                    getPackedListing(_listingTerms),
                    getPackedSignature(_signature),
                    _loanContract,
                    getChainID()
                )
            );

            return
                SignatureChecker.isValidSignatureNow(
                    _signature.signer,
                    ECDSA.toEthSignedMessageHash(message),
                    _signature.signature
                );
        }
    }

    function checkBorrowerSignatureValidityBundle(
        LoanStructures.ListingTerms memory _listingTerms,
        IPackBuilder.BundleElements memory _bundleElements,
        LoanStructures.Signature memory _signature
    ) external view returns (bool) {
        return checkBorrowerSignatureValidityBundle(_listingTerms, _bundleElements, _signature, address(this));
    }

    function checkBorrowerSignatureValidityBundle(
        LoanStructures.ListingTerms memory _listingTerms,
        IPackBuilder.BundleElements memory _bundleElements,
        LoanStructures.Signature memory _signature,
        address _loanContract
    ) public view returns (bool) {
        require(block.timestamp <= _signature.expiry, "Borrower Signature has expired");
        require(_loanContract != address(0), "Loan is zero address");
        if (_signature.signer == address(0)) {
            return false;
        } else {
            bytes32 message = keccak256(
                abi.encodePacked(
                    getPackedListing(_listingTerms),
                    abi.encode(_bundleElements),
                    getPackedSignature(_signature),
                    _loanContract,
                    getChainID()
                )
            );

            return
                SignatureChecker.isValidSignatureNow(
                    _signature.signer,
                    ECDSA.toEthSignedMessageHash(message),
                    _signature.signature
                );
        }
    }

    function checkLenderSignatureValidity(LoanStructures.Offer memory _offer, LoanStructures.Signature memory _signature)
        external
        view
        returns (bool)
    {
        return checkLenderSignatureValidity(_offer, _signature, address(this));
    }

    function checkLenderSignatureValidity(
        LoanStructures.Offer memory _offer,
        LoanStructures.Signature memory _signature,
        address _loanContract
    ) public view returns (bool) {
        require(block.timestamp <= _signature.expiry, "Lender Signature has expired");
        require(_loanContract != address(0), "Loan is zero address");
        if (_signature.signer == address(0)) {
            return false;
        } else {
            bytes32 message = keccak256(
                abi.encodePacked(getPackedOffer(_offer), getPackedSignature(_signature), _loanContract, getChainID())
            );

            return
                SignatureChecker.isValidSignatureNow(
                    _signature.signer,
                    ECDSA.toEthSignedMessageHash(message),
                    _signature.signature
                );
        }
    }

    function checkLenderSignatureValidityBundle(
        LoanStructures.Offer memory _offer,
        IPackBuilder.BundleElements memory _bundleElements,
        LoanStructures.Signature memory _signature
    ) external view returns (bool) {
        return checkLenderSignatureValidityBundle(_offer, _bundleElements, _signature, address(this));
    }

    function checkLenderSignatureValidityBundle(
        LoanStructures.Offer memory _offer,
        IPackBuilder.BundleElements memory _bundleElements,
        LoanStructures.Signature memory _signature,
        address _loanContract
    ) public view returns (bool) {
        require(block.timestamp <= _signature.expiry, "Lender Signature has expired");
        require(_loanContract != address(0), "Loan is zero address");
        if (_signature.signer == address(0)) {
            return false;
        } else {
            bytes32 message = keccak256(
                abi.encodePacked(
                    getPackedOffer(_offer),
                    abi.encode(_bundleElements),
                    getPackedSignature(_signature),
                    _loanContract,
                    getChainID()
                )
            );

            return
                SignatureChecker.isValidSignatureNow(
                    _signature.signer,
                    ECDSA.toEthSignedMessageHash(message),
                    _signature.signature
                );
        }
    }

    function checkLenderRenegotiationSignatureValidity(
        uint256 _loanId,
        uint32 _newLoanDuration,
        uint256 _newMaximumRepaymentAmount,
        uint256 _renegotiationFee,
        LoanStructures.Signature memory _signature
    ) external view returns (bool) {
        return
            checkLenderRenegotiationSignatureValidity(
                _loanId,
                _newLoanDuration,
                _newMaximumRepaymentAmount,
                _renegotiationFee,
                _signature,
                address(this)
            );
    }

    function checkLenderRenegotiationSignatureValidity(
        uint256 _loanId,
        uint32 _newLoanDuration,
        uint256 _newMaximumRepaymentAmount,
        uint256 _renegotiationFee,
        LoanStructures.Signature memory _signature,
        address _loanContract
    ) public view returns (bool) {
        require(block.timestamp <= _signature.expiry, "Renegotiation Signature has expired");
        require(_loanContract != address(0), "Loan is zero address");
        if (_signature.signer == address(0)) {
            return false;
        } else {
            bytes32 message = keccak256(
                abi.encodePacked(
                    _loanId,
                    _newLoanDuration,
                    _newMaximumRepaymentAmount,
                    _renegotiationFee,
                    getPackedSignature(_signature),
                    _loanContract,
                    getChainID()
                )
            );

            return
                SignatureChecker.isValidSignatureNow(
                    _signature.signer,
                    ECDSA.toEthSignedMessageHash(message),
                    _signature.signature
                );
        }
    }

    function getPackedListing(LoanStructures.ListingTerms memory _listingTerms) internal pure returns (bytes memory) {
        return
            abi.encodePacked(
                _listingTerms.loanERC20Denomination,
                _listingTerms.minLoanPrincipalAmount,
                _listingTerms.maxLoanPrincipalAmount,
                _listingTerms.nftCollateralContract,
                _listingTerms.nftCollateralId,
                _listingTerms.revenueSharePartner,
                _listingTerms.minLoanDuration,
                _listingTerms.maxLoanDuration,
                _listingTerms.maxInterestRateForDurationInBasisPoints,
                _listingTerms.referralFeeInBasisPoints
            );
    }

    function getPackedOffer(LoanStructures.Offer memory _offer) internal pure returns (bytes memory) {
        return
            abi.encodePacked(
                _offer.loanERC20Denomination,
                _offer.loanPrincipalAmount,
                _offer.maximumRepaymentAmount,
                _offer.nftCollateralContract,
                _offer.nftCollateralId,
                _offer.referrer,
                _offer.loanDuration,
                _offer.loanAdminFeeInBasisPoints
            );
    }

    function getPackedSignature(LoanStructures.Signature memory _signature) internal pure returns (bytes memory) {
        return abi.encodePacked(_signature.signer, _signature.nonce, _signature.expiry);
    }
}