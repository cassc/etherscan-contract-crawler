//SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import {StateEnum} from "../structs/StateEnum.sol";

/// @author Amit Molek
/// @dev Diamond compatible storage for group state
library StorageState {
    struct DiamondStorage {
        /// @dev State of the group
        StateEnum state;
    }

    bytes32 public constant DIAMOND_STORAGE_POSITION =
        keccak256("antic.storage.State");

    function diamondStorage()
        internal
        pure
        returns (DiamondStorage storage ds)
    {
        bytes32 storagePosition = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := storagePosition
        }
    }
}