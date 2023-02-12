// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

import {TrackableBurnableERC1155__InitializableStorage} from "./TrackableBurnableERC1155__InitializableStorage.sol";

abstract contract TrackableBurnableERC1155__Initializable {
    using TrackableBurnableERC1155__InitializableStorage for TrackableBurnableERC1155__InitializableStorage.Layout;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(
            TrackableBurnableERC1155__InitializableStorage
                .layout()
                ._initializing
                ? _isConstructor()
                : !TrackableBurnableERC1155__InitializableStorage
                    .layout()
                    ._initialized,
            "TrackableBurnableERC1155__Initializable: contract is already initialized"
        );

        bool isTopLevelCall = !TrackableBurnableERC1155__InitializableStorage
            .layout()
            ._initializing;
        if (isTopLevelCall) {
            TrackableBurnableERC1155__InitializableStorage
                .layout()
                ._initializing = true;
            TrackableBurnableERC1155__InitializableStorage
                .layout()
                ._initialized = true;
        }

        _;

        if (isTopLevelCall) {
            TrackableBurnableERC1155__InitializableStorage
                .layout()
                ._initializing = false;
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(
            TrackableBurnableERC1155__InitializableStorage
                .layout()
                ._initializing,
            "TrackableBurnableERC1155__Initializable: contract is not initializing"
        );
        _;
    }

    /// @dev Returns true if and only if the function is running in the constructor
    function _isConstructor() private view returns (bool) {
        // extcodesize checks the size of the code stored in an address, and
        // address returns the current address. Since the code is still not
        // deployed when running a constructor, any checks on its code size will
        // yield zero, making it an effective way to detect if a contract is
        // under construction or not.
        address self = address(this);
        uint256 cs;
        assembly {
            cs := extcodesize(self)
        }
        return cs == 0;
    }
}