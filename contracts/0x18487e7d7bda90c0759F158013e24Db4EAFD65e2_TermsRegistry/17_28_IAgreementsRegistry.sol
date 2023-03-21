// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8;

interface IAgreementsRegistryV0 {
    event TermsActivationStatusUpdated(address indexed token, bool isActivated);
    event TermsUpdated(address indexed token, string termsURI, uint8 termsVersion);
    event TermsAccepted(address indexed token, string termsURI, uint8 termsVersion, address indexed acceptor);

    function acceptTerms(address _token) external;

    function acceptTerms(address _token, address _acceptor) external;

    function setTermsActivation(address _token, bool _active) external;

    function setTermsURI(address _token, string calldata _termsURI) external;

    function getTermsDetails(address _token)
        external
        view
        returns (
            string memory termsURI,
            uint8 termsVersion,
            bool termsActivated
        );

    function hasAcceptedTerms(address _token, address _address) external view returns (bool hasAccepted);

    function hasAcceptedTerms(
        address _token,
        address _address,
        uint8 _termsVersion
    ) external view returns (bool hasAccepted);
}

interface IAgreementsRegistryV1 is IAgreementsRegistryV0 {
    event TermsWithSignatureAccepted(
        address indexed token,
        string termsURI,
        uint8 termsVersion,
        address indexed acceptor,
        bytes signature
    );

    function acceptTerms(
        address _token,
        address _acceptor,
        bytes calldata _signature
    ) external;

    function batchAcceptTerms(address _token, address[] calldata _acceptors) external;
}