// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

// Not sure if we should use an enum here because the integrations are not fixed
// We could use a keccak("IntegrationName") instead, this contract will have to be upgraded if we add a new integration
// Because solidity validates enum params at runtime
enum Integration {
    GMXRequests,
    GMXPositions
}

library IntegrationDataTrackerStorage {
    bytes32 internal constant STORAGE_SLOT =
        keccak256('valio.storage.IntegationDataTracker');

    // solhint-disable-next-line ordering
    struct Layout {
        // used as the namespace for the data -> poolAddress -> data[]
        mapping(Integration => mapping(address => bytes[])) trackedData;
    }

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;

        assembly {
            l.slot := slot
        }
    }
}