// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../PicklePoint.sol";

library ClaimableStorage {
    struct Layout {
        PicklePoint picklePoint;
    }

    bytes32 internal constant APP_STORAGE_SLOT =
        keccak256("NiftyKit.contracts.Claimable");

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = APP_STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}