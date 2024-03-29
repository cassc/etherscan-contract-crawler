// SPDX-License-Identifier: Apache-2.0

// Generated by impl.ts. Will be overwritten.
// Filename: './BaseCedarPaymentSplitterV2.sol'

pragma solidity ^0.8.4;

import "../../api/impl/ICedarPaymentSplitter.sol";
import "../../api/ICedarFeatures.sol";
import "../../api/ICedarVersioned.sol";
import "../../api/splitpayment/ICedarSplitPayment.sol";

/// Inherit from this base to implement introspection
abstract contract BaseCedarPaymentSplitterV2 is ICedarFeaturesV0, ICedarVersionedV2, ICedarSplitPaymentV0 {
    function supportedFeatures() override public pure returns (string[] memory features) {
        features = new string[](3);
        features[0] = "ICedarFeatures.sol:ICedarFeaturesV0";
        features[1] = "ICedarVersioned.sol:ICedarVersionedV2";
        features[2] = "splitpayment/ICedarSplitPayment.sol:ICedarSplitPaymentV0";
    }

    /// This needs to be public to be callable from initialize via delegatecall
    function minorVersion() virtual override public pure returns (uint256 minor, uint256 patch);

    function implementationVersion() override public pure returns (uint256 major, uint256 minor, uint256 patch) {
        (minor, patch) = minorVersion();
        major = 2;
    }

    function implementationInterfaceId() virtual override public pure returns (string memory interfaceId) {
        interfaceId = "impl/ICedarPaymentSplitter.sol:ICedarPaymentSplitterV2";
    }

    function supportsInterface(bytes4 interfaceID) virtual override public view returns (bool) {
        return (interfaceID == type(IERC165Upgradeable).interfaceId) || ((interfaceID == type(ICedarFeaturesV0).interfaceId) || ((interfaceID == type(ICedarVersionedV2).interfaceId) || ((interfaceID == type(ICedarSplitPaymentV0).interfaceId) || (interfaceID == type(ICedarPaymentSplitterV2).interfaceId))));
    }

    function isICedarFeaturesV0() override public pure returns (bool) {
        return true;
    }
}