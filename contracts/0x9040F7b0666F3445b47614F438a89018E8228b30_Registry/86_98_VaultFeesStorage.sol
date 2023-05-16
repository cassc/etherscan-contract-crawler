// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

library VaultFeesStorage {
    bytes32 internal constant STORAGE_SLOT =
        keccak256('valio.storage.VaultFees');

    struct Layout {
        uint managerStreamingFee;
        uint managerPerformanceFee;
        uint announcedFeeIncreaseTimestamp;
        uint announcedManagerStreamingFee;
        uint announcedManagerPerformanceFee;
    }

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;

        assembly {
            l.slot := slot
        }
    }
}