// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

library OnboardingStorage {
    bytes32 private constant STORAGE_SLOT =
        keccak256("niftykit.apps.onboarding.storage");

    struct Layout {
        mapping(bytes => bool) _isSignatureVerified;
        mapping(string => uint256) _totalMintedPerLink;
        mapping(string => mapping(address => uint256)) _mintedTokensPerLinkPerWallet;
    }

    function layout() internal pure returns (Layout storage ds) {
        bytes32 position = STORAGE_SLOT;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            ds.slot := position
        }
    }
}