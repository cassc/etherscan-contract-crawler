// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8;

interface ITermsErrorsV0 {
    error TermsNotActivated();
    error TermsStatusAlreadySet();
    error TermsURINotSet();
    error TermsUriAlreadySet();
    error TermsAlreadyAccepted(uint8 acceptedVersion);
    error SignatureVerificationFailed();
    error TermsCanOnlyBeSetByOwner(address token);
    error TermsNotActivatedForToken(address token);
    error TermsStatusAlreadySetForToken(address token);
    error TermsURINotSetForToken(address token);
    error TermsUriAlreadySetForToken(address token);
    error TermsAlreadyAcceptedForToken(address token, uint8 acceptedVersion);
}