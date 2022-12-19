//SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import {ReentrancyGuardStatus} from "../structs/ReentrancyGuardStatus.sol";

/// @author Amit Molek
/// @dev Diamond compatible storage for reentrancy guard
library StorageReentrancyGuard {
    struct DiamondStorage {
        /// @dev
        ReentrancyGuardStatus status;
    }

    bytes32 public constant DIAMOND_STORAGE_POSITION =
        keccak256("antic.storage.ReentrancyGuard");

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