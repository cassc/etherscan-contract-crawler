// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

// Provides introspection over which token distribution modalities are enabled
// Note: ICedarVersioned tells us which features are implemented at the function levle, whereas this interface can tell
// us which modalities are actually enabled
interface ICedarIssuanceV0 {
    enum IssuanceMode {
        SpecificToken,
        AnyToken
    }

    enum PaymentType {
        None,
        Native,
        ERC20
    }

    enum AuthType {
        TrustedSender,
        Merkle,
        Signature
    }

    function issuanceModes() external view returns (IssuanceMode[] calldata);

    function paymentTypes() external view returns (PaymentType[] calldata);

    function authTypes() external view returns (AuthType[] calldata);
}

interface ICedarIssuanceV1 {
    function foo() external view returns (uint256);
}