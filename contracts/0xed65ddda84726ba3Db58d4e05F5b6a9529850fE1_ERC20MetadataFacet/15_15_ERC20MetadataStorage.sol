// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import {IERC20Metadata} from "./../interfaces/IERC20Metadata.sol";
import {ProxyInitialization} from "./../../../proxy/libraries/ProxyInitialization.sol";
import {InterfaceDetectionStorage} from "./../../../introspection/libraries/InterfaceDetectionStorage.sol";

library ERC20MetadataStorage {
    using InterfaceDetectionStorage for InterfaceDetectionStorage.Layout;
    using ERC20MetadataStorage for ERC20MetadataStorage.Layout;

    struct Layout {
        string uri;
    }

    bytes32 internal constant LAYOUT_STORAGE_SLOT = bytes32(uint256(keccak256("animoca.core.token.ERC20.ERC20Metadata.storage")) - 1);

    /// @notice Marks the following ERC165 interface(s) as supported: ERC20Metadata.
    function init() internal {
        InterfaceDetectionStorage.layout().setSupportedInterface(type(IERC20Metadata).interfaceId, true);
    }

    /// @notice Sets the token URI.
    /// @param uri The token URI.
    function setTokenURI(Layout storage s, string calldata uri) internal {
        s.uri = uri;
    }

    /// @notice Gets the token metadata URI.
    /// @return uri The token metadata URI.
    function tokenURI(Layout storage s) internal view returns (string memory uri) {
        return s.uri;
    }

    function layout() internal pure returns (Layout storage s) {
        bytes32 position = LAYOUT_STORAGE_SLOT;
        assembly {
            s.slot := position
        }
    }
}