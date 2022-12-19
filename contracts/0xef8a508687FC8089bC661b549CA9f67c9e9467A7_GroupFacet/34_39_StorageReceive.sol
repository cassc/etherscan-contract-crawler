//SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

/// @author Amit Molek
/// @dev Diamond compatible storage for receive funds
library StorageReceive {
    struct DiamondStorage {
        /// Map between a member and amount of funds it can withdraw
        mapping(address => uint256) withdrawable;
        /// Total withdrawable amount
        uint256 totalWithdrawable;
    }

    bytes32 public constant DIAMOND_STORAGE_POSITION =
        keccak256("antic.storage.Receive");

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