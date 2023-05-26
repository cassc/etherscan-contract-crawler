// SPDX-License-Identifier: UNLICENSE

pragma solidity ^0.8.4;

import "../descriptor/IDescriptor.sol";

library TAGStorage {

    struct Layout {
        bool operatorFilteringEnabled;
        IDescriptor descriptor;
    }

    bytes32 internal constant STORAGE_SLOT = keccak256('TokyoAlternativeGirls.contracts.storage.facet');

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}