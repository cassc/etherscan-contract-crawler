// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import { EnumerableSet } from '@solidstate/contracts/data/EnumerableSet.sol';

library ShardVaultStorage {
    struct Layout {
        uint256 shardValue;
        uint256 accruedFees;
        uint256 accruedJPEG;
        uint256 cumulativeETHPerShard;
        uint256 cumulativeJPEGPerShard;
        mapping(uint256 => uint256) claimedETHPerShard;
        mapping(uint256 => uint256) claimedJPEGPerShard;
        address collection;
        uint48 whitelistEndsAt;
        uint16 saleFeeBP;
        uint16 acquisitionFeeBP;
        uint16 yieldFeeBP;
        uint64 maxSupply;
        uint64 maxMintBalance;
        uint64 reservedSupply;
        uint16 ltvBufferBP;
        uint16 ltvDeviationBP;
        bool isInvested;
        bool isEnabled;
        bool isPUSDVault;
        bool isYieldClaiming;
        address marketPlaceHelper;
        address jpegdVault;
        address jpegdVaultHelper;
        address jpegdLP;
        EnumerableSet.UintSet ownedTokenIds;
        mapping(address => bool) authorized;
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256('insrt.contracts.storage.ShardVault');

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}