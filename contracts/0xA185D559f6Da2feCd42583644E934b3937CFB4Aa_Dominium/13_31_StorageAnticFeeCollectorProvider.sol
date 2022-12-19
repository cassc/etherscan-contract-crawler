//SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

/// @author Amit Molek
/// @dev Diamond compatible storage for Antic fee collector provider
library StorageAnticFeeCollectorProvider {
    uint16 public constant MAX_ANTIC_FEE_PERCENTAGE = 500; // 50%

    struct DiamondStorage {
        /// @dev Address that the Antic fees will get sent to
        address anticFeeCollector;
        /// @dev Antic join fee percentage out of 1000
        /// e.g. 25 -> 25/1000 = 2.5%
        uint16 joinFeePercentage;
        /// @dev Antic sell/receive fee percentage out of 1000
        /// e.g. 25 -> 25/1000 = 2.5%
        uint16 sellFeePercentage;
    }

    bytes32 public constant DIAMOND_STORAGE_POSITION =
        keccak256("antic.dominium.storage.AnticFeeCollectorProvider");

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