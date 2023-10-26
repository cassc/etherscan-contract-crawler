// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.19;

import "../../utils/Constants.sol";
import { DiamondStorage, ImplementationStorage, TransmuterStorage } from "../Storage.sol";

/// @title LibStorage
/// @author Angle Labs, Inc.
library LibStorage {
    /// @notice Returns the storage struct stored at the `DIAMOND_STORAGE_POSITION` slot
    /// @dev This struct handles the logic of the different facets used in the diamond proxy
    function diamondStorage() internal pure returns (DiamondStorage storage ds) {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    /// @notice Returns the storage struct stored at the `TRANSMUTER_STORAGE_POSITION` slot
    /// @dev This struct handles the particular logic of the Transmuter system
    function transmuterStorage() internal pure returns (TransmuterStorage storage ts) {
        bytes32 position = TRANSMUTER_STORAGE_POSITION;
        assembly {
            ts.slot := position
        }
    }

    /// @notice Returns the storage struct stored at the `IMPLEMENTATION_STORAGE_POSITION` slot
    /// @dev This struct handles the logic for making the contract easily usable on Etherscan
    function implementationStorage() internal pure returns (ImplementationStorage storage ims) {
        bytes32 position = IMPLEMENTATION_STORAGE_POSITION;
        assembly {
            ims.slot := position
        }
    }
}