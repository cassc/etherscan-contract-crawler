// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

library VaultOwnershipStorage {
    bytes32 internal constant STORAGE_SLOT =
        keccak256('valio.storage.VaultOwnership');

    // TODO: Move to interface
    // solhint-disable-next-line ordering
    struct Holding {
        uint totalShares;
        uint lastStreamingFeeTime;
        uint lastPerformanceFeeUnitPrice;
        uint streamingFeeDiscount;
        uint performanceFeeDiscount;
        uint streamingFee;
        uint performanceFee;
        uint unlockTime;
        uint averageEntryPrice;
        uint lastManagerFeeLevyTime;
        uint lastBurnTime;
    }

    // solhint-disable-next-line ordering
    struct Layout {
        // The manager is issued token 0; The protocol is issued token 1; all other tokens are issued to investors
        // All fees are levied to token 0 and a portion to token 1;
        // tokenId to Holding
        mapping(uint => Holding) holdings;
        uint totalShares;
        uint256 _tokenIdCounter;
    }

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;

        assembly {
            l.slot := slot
        }
    }
}