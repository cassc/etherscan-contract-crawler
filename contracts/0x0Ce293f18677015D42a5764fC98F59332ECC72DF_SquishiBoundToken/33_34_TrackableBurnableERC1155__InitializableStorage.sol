// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library TrackableBurnableERC1155__InitializableStorage {
    struct Layout {
        bool _initialized;
        bool _initializing;
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256("trackableburnableerc1155.contracts.storage.initializable");

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}