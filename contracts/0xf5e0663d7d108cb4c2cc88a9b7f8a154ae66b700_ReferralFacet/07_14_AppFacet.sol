// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {InternalERC721AUpgradeable} from "./InternalERC721AUpgradeable.sol";
import {InternalOwnableRoles} from "./InternalOwnableRoles.sol";
import {INiftyKitAppRegistry} from "../interfaces/INiftyKitAppRegistry.sol";
import {BaseStorage} from "../diamond/BaseStorage.sol";

abstract contract AppFacet is InternalOwnableRoles, InternalERC721AUpgradeable {
    function _callAppFunction(bytes32 appId, bytes memory data) internal {
        INiftyKitAppRegistry.App storage app = BaseStorage.layout()._apps[
            appId
        ];
        address implementation = app.implementation;
        require(implementation != address(0), "App not installed");
        (bool success, ) = implementation.delegatecall(data);

        require(success, "Delegated call failed");
    }

    /**
     * Need this for ERC721A, when we call `_totalSupply()` this is read from code.
     */
    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    /**
     * Override this to use the trusted forwarder.
     */
    function _msgSenderERC721A()
        internal
        view
        override
        returns (address sender)
    {
        if (_isTrustedForwarder(msg.sender)) {
            // The assembly code is more direct than the Solidity version using `abi.decode`.
            /// @solidity memory-safe-assembly
            assembly {
                sender := shr(96, calldataload(sub(calldatasize(), 20)))
            }
        } else {
            return super._msgSenderERC721A();
        }
    }

    function _msgDataERC721A() internal view virtual returns (bytes calldata) {
        if (_isTrustedForwarder(msg.sender)) {
            return msg.data[:msg.data.length - 20];
        } else {
            return msg.data;
        }
    }

    function _isTrustedForwarder(
        address forwarder
    ) internal view returns (bool) {
        return BaseStorage.layout()._trustedForwarder == forwarder;
    }
}