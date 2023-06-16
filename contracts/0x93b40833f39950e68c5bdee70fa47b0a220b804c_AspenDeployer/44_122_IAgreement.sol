// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8;

interface ICedarAgreementV0 {
    // Accept legal terms associated with transfer of this NFT
    function acceptTerms() external;

    function userAgreement() external view returns (string memory);

    function termsActivated() external view returns (bool);

    function setTermsStatus(bool _status) external;

    function getAgreementStatus(address _address) external view returns (bool sig);

    function storeTermsAccepted(address _acceptor, bytes calldata _signature) external;
}

interface ICedarAgreementV1 {
    // Accept legal terms associated with transfer of this NFT
    event TermsActivationStatusUpdated(bool isActivated);
    event TermsUpdated(string termsURI, uint8 termsVersion);
    event TermsAccepted(string termsURI, uint8 termsVersion, address indexed acceptor);

    function acceptTerms() external;

    function acceptTerms(address _acceptor) external;

    function setTermsActivation(bool _active) external;

    function setTermsURI(string calldata _termsURI) external;

    function getTermsDetails()
        external
        view
        returns (
            string memory termsURI,
            uint8 termsVersion,
            bool termsActivated
        );

    function hasAcceptedTerms(address _address) external view returns (bool hasAccepted);

    //    function hasAcceptedTerms(address _address, uint8 _termsVersion) external view returns (bool hasAccepted);
}

interface IPublicAgreementV0 {
    function acceptTerms() external;

    function getTermsDetails()
        external
        view
        returns (
            string memory termsURI,
            uint8 termsVersion,
            bool termsActivated
        );

    function hasAcceptedTerms(address _address) external view returns (bool hasAccepted);

    function hasAcceptedTerms(address _address, uint8 _termsVersion) external view returns (bool hasAccepted);
}

interface IPublicAgreementV1 is IPublicAgreementV0 {
    /// @dev Emitted when the terms are accepted.
    event TermsAccepted(string termsURI, uint8 termsVersion, address indexed acceptor);
}

interface IPublicAgreementV2 {
    function acceptTerms() external;

    /// @dev Emitted when the terms are accepted.
    event TermsAccepted(string termsURI, uint8 termsVersion, address indexed acceptor);
}

// Note: Deprecated in favor of IRestrictedAgreementV2
interface IDelegatedAgreementV0 {
    /// @dev Emitted when the terms are accepted using singature of acceptor.
    event TermsWithSignatureAccepted(string termsURI, uint8 termsVersion, address indexed acceptor, bytes signature);

    function acceptTerms(address _acceptor, bytes calldata _signature) external;

    function batchAcceptTerms(address[] calldata _acceptors) external;
}

interface IDelegatedAgreementV1 {
    function getTermsDetails()
        external
        view
        returns (
            string memory termsURI,
            uint8 termsVersion,
            bool termsActivated
        );

    function hasAcceptedTerms(address _address) external view returns (bool hasAccepted);

    function hasAcceptedTerms(address _address, uint8 _termsVersion) external view returns (bool hasAccepted);
}

interface IRestrictedAgreementV0 {
    function acceptTerms(address _acceptor) external;

    function setTermsActivation(bool _active) external;

    function setTermsURI(string calldata _termsURI) external;
}

interface IRestrictedAgreementV1 is IRestrictedAgreementV0 {
    /// @dev Emitted when the terms are accepted by an issuer.
    event TermsAcceptedForAddress(string termsURI, uint8 termsVersion, address indexed acceptor, address caller);
    /// @dev Emitted when the terms are activated/deactivated.
    event TermsActivationStatusUpdated(bool isActivated);
    /// @dev Emitted when the terms URI is updated.
    event TermsUpdated(string termsURI, uint8 termsVersion);
}

interface IRestrictedAgreementV2 is IRestrictedAgreementV1 {
    /// @dev Emitted when the terms are accepted using singature of acceptor.
    event TermsWithSignatureAccepted(string termsURI, uint8 termsVersion, address indexed acceptor, bytes signature);

    function acceptTerms(address _acceptor, bytes calldata _signature) external;

    function batchAcceptTerms(address[] calldata _acceptors) external;
}

interface IRestrictedAgreementV3 {
    /// @dev Emitted when the terms are accepted by an issuer.
    event TermsAcceptedForAddress(string termsURI, uint8 termsVersion, address indexed acceptor, address caller);
    /// @dev Emitted when the terms are activated/deactivated.
    event TermsRequiredStatusUpdated(bool isActivated);
    /// @dev Emitted when the terms URI is updated.
    event TermsUpdated(string termsURI, uint8 termsVersion);
    /// @dev Emitted when the terms are accepted using singature of acceptor.
    event TermsWithSignatureAccepted(string termsURI, uint8 termsVersion, address indexed acceptor, bytes signature);

    function acceptTerms(address _acceptor) external;

    function setTermsRequired(bool _active) external;

    function setTermsURI(string calldata _termsURI) external;

    function acceptTerms(address _acceptor, bytes calldata _signature) external;

    function batchAcceptTerms(address[] calldata _acceptors) external;
}