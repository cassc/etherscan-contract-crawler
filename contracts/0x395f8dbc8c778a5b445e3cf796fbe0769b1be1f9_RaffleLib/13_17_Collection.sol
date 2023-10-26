// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "openzeppelin-contracts/contracts/utils/math/Math.sol";
import "openzeppelin-contracts/contracts/utils/math/SafeCast.sol";

import "../library/RollingBuckets.sol";
import "../library/ERC721Transfer.sol";

import "../Errors.sol";
import "../Constants.sol";
import "./User.sol";
import "./Helper.sol";
import {SafeBox, CollectionState, AuctionInfo, CollectionAccount, UserFloorAccount, LockParam} from "./Structs.sol";
import {SafeBoxLib} from "./SafeBox.sol";

import "../interface/IFlooring.sol";

library CollectionLib {
    using SafeBoxLib for SafeBox;
    using SafeCast for uint256;
    using RollingBuckets for mapping(uint256 => uint256);
    using UserLib for CollectionAccount;
    using UserLib for UserFloorAccount;

    event LockNft(
        address indexed sender,
        address indexed onBehalfOf,
        address indexed collection,
        uint256[] tokenIds,
        uint256[] safeBoxKeys,
        uint256 safeBoxExpiryTs,
        uint256 minMaintCredit,
        address proxyCollection
    );
    event ExtendKey(
        address indexed operator,
        address indexed collection,
        uint256[] tokenIds,
        uint256[] safeBoxKeys,
        uint256 safeBoxExpiryTs,
        uint256 minMaintCredit
    );
    event UnlockNft(
        address indexed operator,
        address indexed receiver,
        address indexed collection,
        uint256[] tokenIds,
        address proxyCollection
    );
    event RemoveExpiredKey(
        address indexed operator,
        address indexed onBehalfOf,
        address indexed collection,
        uint256[] tokenIds,
        uint256[] safeBoxKeys
    );
    event ClaimExpiredNft(
        address indexed operator,
        address indexed receiver,
        address indexed collection,
        uint256[] tokenIds,
        uint256 creditCost,
        address proxyCollection
    );
    event FragmentNft(
        address indexed operator, address indexed onBehalfOf, address indexed collection, uint256[] tokenIds
    );
    event ClaimRandomNft(
        address indexed operator,
        address indexed receiver,
        address indexed collection,
        uint256[] tokenIds,
        uint256 creditCost
    );

    function fragmentNFTs(
        CollectionState storage collectionState,
        address collection,
        uint256[] memory nftIds,
        address onBehalfOf
    ) public {
        uint256 nftLen = nftIds.length;
        unchecked {
            for (uint256 i; i < nftLen; ++i) {
                collectionState.freeTokenIds.push(nftIds[i]);
            }
        }
        collectionState.floorToken.mint(onBehalfOf, Constants.FLOOR_TOKEN_AMOUNT * nftLen);
        ERC721Transfer.safeBatchTransferFrom(collection, msg.sender, address(this), nftIds);

        emit FragmentNft(msg.sender, onBehalfOf, collection, nftIds);
    }

    struct LockInfo {
        bool isInfinite;
        uint256 currentBucket;
        uint256 newExpiryBucket;
        uint256 totalManaged;
        uint256 newRequireLockCredit;
        uint64 infiniteCnt;
    }

    function lockNfts(
        CollectionState storage collection,
        UserFloorAccount storage account,
        LockParam memory param,
        address onBehalfOf
    ) public returns (uint256 totalCreditCost) {
        if (onBehalfOf == address(this)) revert Errors.InvalidParam();

        uint8 vipLevel = uint8(param.vipLevel);
        uint256 totalCredit = account.ensureVipCredit(vipLevel, param.creditToken);
        Helper.ensureMaxLocking(vipLevel, param.expiryTs);
        Helper.ensureProxyVipLevel(Constants.getVipLevel(totalCredit), param.collection != param.proxyCollection);

        /// cache value to avoid multi-reads
        uint256 minMaintCredit = account.minMaintCredit;
        uint256[] memory nftIds = param.nftIds;
        uint256[] memory newKeys;
        {
            CollectionAccount storage userCollectionAccount = account.getOrAddCollection(param.collection);

            (totalCreditCost, newKeys) = _lockNfts(collection, userCollectionAccount, nftIds, param.expiryTs, vipLevel);

            // compute max credit for locking cost
            uint96 totalLockingCredit = userCollectionAccount.totalLockingCredit;
            {
                uint256 creditBuffer;
                unchecked {
                    creditBuffer = totalCredit - totalLockingCredit;
                }
                if (totalCreditCost > creditBuffer || totalCreditCost > param.maxCreditCost) {
                    revert Errors.InsufficientCredit();
                }
            }

            totalLockingCredit += totalCreditCost.toUint96();
            userCollectionAccount.totalLockingCredit = totalLockingCredit;

            if (totalLockingCredit > minMaintCredit) {
                account.minMaintCredit = totalLockingCredit;
                minMaintCredit = totalLockingCredit;
            }
        }

        account.updateVipKeyCount(vipLevel, int256(nftIds.length));
        /// mint for `onBehalfOf`, transfer from msg.sender
        collection.floorToken.mint(onBehalfOf, Constants.FLOOR_TOKEN_AMOUNT * nftIds.length);
        ERC721Transfer.safeBatchTransferFrom(param.proxyCollection, msg.sender, address(this), nftIds);

        emit LockNft(
            msg.sender,
            onBehalfOf,
            param.collection,
            nftIds,
            newKeys,
            param.expiryTs,
            minMaintCredit,
            param.proxyCollection
        );
    }

    function _lockNfts(
        CollectionState storage collectionState,
        CollectionAccount storage account,
        uint256[] memory nftIds,
        uint256 expiryTs, // treat 0 as infinite lock.
        uint8 vipLevel
    ) private returns (uint256, uint256[] memory) {
        LockInfo memory info = LockInfo({
            isInfinite: expiryTs == 0,
            currentBucket: Helper.counterStamp(block.timestamp),
            newExpiryBucket: Helper.counterStamp(expiryTs),
            totalManaged: collectionState.activeSafeBoxCnt + collectionState.freeTokenIds.length,
            newRequireLockCredit: 0,
            infiniteCnt: collectionState.infiniteCnt
        });
        if (info.isInfinite) {
            /// if it is infinite lock, we need load all buckets to calculate the staking cost
            info.newExpiryBucket = Helper.counterStamp(block.timestamp + Constants.MAX_LOCKING_PERIOD);
        }

        uint256[] memory buckets = Helper.prepareBucketUpdate(collectionState, info.currentBucket, info.newExpiryBucket);
        /// @dev `keys` used to log info, we just compact its fields into one 256 bits number
        uint256[] memory keys = new uint256[](nftIds.length);

        for (uint256 idx; idx < nftIds.length;) {
            uint256 lockedCredit = updateCountersAndGetSafeboxCredit(buckets, info, vipLevel);

            if (info.isInfinite) ++info.infiniteCnt;

            SafeBoxKey memory key = SafeBoxKey({
                keyId: Helper.generateNextKeyId(collectionState),
                lockingCredit: lockedCredit.toUint96(),
                vipLevel: vipLevel
            });

            account.addSafeboxKey(nftIds[idx], key);
            addSafeBox(
                collectionState, nftIds[idx], SafeBox({keyId: key.keyId, expiryTs: uint32(expiryTs), owner: msg.sender})
            );

            keys[idx] = SafeBoxLib.encodeSafeBoxKey(key);

            info.newRequireLockCredit += lockedCredit;
            unchecked {
                ++info.totalManaged;
                ++idx;
            }
        }

        if (info.isInfinite) {
            collectionState.infiniteCnt = info.infiniteCnt;
        } else {
            collectionState.countingBuckets.batchSet(info.currentBucket, buckets);
            if (info.newExpiryBucket > collectionState.lastUpdatedBucket) {
                collectionState.lastUpdatedBucket = uint64(info.newExpiryBucket);
            }
        }

        return (info.newRequireLockCredit, keys);
    }

    function unlockNfts(
        CollectionState storage collection,
        UserFloorAccount storage userAccount,
        address proxyCollection,
        address collectionId,
        uint256[] memory nftIds,
        uint256 maxExpiryTs,
        address receiver
    ) public {
        CollectionAccount storage userCollectionAccount = userAccount.getByKey(collectionId);
        SafeBoxKey[] memory releasedKeys = _unlockNfts(collection, maxExpiryTs, nftIds, userCollectionAccount);

        collection.floorToken.burn(msg.sender, Constants.FLOOR_TOKEN_AMOUNT * nftIds.length);

        for (uint256 i = 0; i < releasedKeys.length;) {
            userAccount.updateVipKeyCount(releasedKeys[i].vipLevel, -1);
            unchecked {
                ++i;
            }
        }
        ERC721Transfer.safeBatchTransferFrom(proxyCollection, address(this), receiver, nftIds);

        emit UnlockNft(msg.sender, receiver, collectionId, nftIds, proxyCollection);
    }

    function _unlockNfts(
        CollectionState storage collectionState,
        uint256 maxExpiryTs,
        uint256[] memory nftIds,
        CollectionAccount storage userCollectionAccount
    ) private returns (SafeBoxKey[] memory) {
        if (maxExpiryTs > 0 && maxExpiryTs < block.timestamp) revert Errors.SafeBoxHasExpire();
        SafeBoxKey[] memory expiredKeys = new SafeBoxKey[](nftIds.length);
        uint256 currentBucketTime = Helper.counterStamp(block.timestamp);
        uint256 creditToRelease = 0;
        uint256[] memory buckets;

        /// if maxExpiryTs == 0, it means all nftIds in this batch being locked infinitely that we don't need to update countingBuckets
        if (maxExpiryTs > 0) {
            uint256 maxExpiryBucketTime = Math.min(Helper.counterStamp(maxExpiryTs), collectionState.lastUpdatedBucket);
            buckets = collectionState.countingBuckets.batchGet(currentBucketTime, maxExpiryBucketTime);
        }

        for (uint256 i; i < nftIds.length;) {
            uint256 nftId = nftIds[i];

            if (Helper.hasActiveActivities(collectionState, nftId)) revert Errors.NftHasActiveActivities();

            (SafeBox storage safeBox, SafeBoxKey storage safeBoxKey) =
                Helper.useSafeBoxAndKey(collectionState, userCollectionAccount, nftId);

            creditToRelease += safeBoxKey.lockingCredit;
            if (safeBox.isInfiniteSafeBox()) {
                --collectionState.infiniteCnt;
            } else {
                uint256 limit = Helper.counterStamp(safeBox.expiryTs) - currentBucketTime;
                if (limit > buckets.length) revert();
                for (uint256 idx; idx < limit;) {
                    --buckets[idx];
                    unchecked {
                        ++idx;
                    }
                }
            }

            expiredKeys[i] = safeBoxKey;

            removeSafeBox(collectionState, nftId);
            userCollectionAccount.removeSafeboxKey(nftId);

            unchecked {
                ++i;
            }
        }

        userCollectionAccount.totalLockingCredit -= creditToRelease.toUint96();
        if (buckets.length > 0) {
            collectionState.countingBuckets.batchSet(currentBucketTime, buckets);
        }

        return expiredKeys;
    }

    function claimExpiredNfts(
        CollectionState storage collectionState,
        mapping(address => UserFloorAccount) storage userAccounts,
        address creditToken,
        address proxyCollection,
        address collectionId,
        uint256[] memory nftIds,
        uint256 maxCreditCost,
        address receiver
    ) public returns (uint256 totalCreditCost) {
        for (uint256 i = 0; i < nftIds.length;) {
            SafeBox storage safeBox = Helper.useSafeBox(collectionState, nftIds[i]);
            if (!safeBox.isSafeBoxExpired()) revert Errors.SafeBoxHasNotExpire();
            if (!Helper.isAuctionPeriodOver(safeBox)) revert Errors.AuctionHasNotCompleted();

            removeSafeBox(collectionState, nftIds[i]);

            unchecked {
                ++i;
            }
        }

        uint256 currentlyLocked = getActiveSafeBoxes(collectionState, block.timestamp) + collectionState.infiniteCnt;
        UserFloorAccount storage userAccount = userAccounts[msg.sender];

        totalCreditCost = nftIds.length
            * Constants.getClaimExpiredCost(
                currentlyLocked,
                collectionState.activeSafeBoxCnt + collectionState.freeTokenIds.length,
                Constants.getVipLevel(userAccount.tokenBalance(creditToken))
            );
        if (totalCreditCost > maxCreditCost) {
            revert Errors.InsufficientCredit();
        }

        userAccount.transferToken(userAccounts[address(this)], creditToken, totalCreditCost, true);
        collectionState.floorToken.burn(msg.sender, Constants.FLOOR_TOKEN_AMOUNT * nftIds.length);
        ERC721Transfer.safeBatchTransferFrom(proxyCollection, address(this), receiver, nftIds);

        emit ClaimExpiredNft(msg.sender, receiver, collectionId, nftIds, totalCreditCost, proxyCollection);
    }

    function extendLockingForKeys(
        CollectionState storage collection,
        UserFloorAccount storage userAccount,
        LockParam memory param
    ) public returns (uint256 totalCreditCost) {
        uint8 newVipLevel = uint8(param.vipLevel);
        uint256 totalCredit = userAccount.ensureVipCredit(newVipLevel, param.creditToken);
        Helper.ensureMaxLocking(newVipLevel, param.expiryTs);

        uint256 minMaintCredit = userAccount.minMaintCredit;
        uint256[] memory safeBoxKeys;
        {
            CollectionAccount storage collectionAccount = userAccount.getOrAddCollection(param.collection);

            // extend lock duration
            int256[] memory vipLevelDiffs;
            (vipLevelDiffs, totalCreditCost, safeBoxKeys) =
                _extendLockingForKeys(collection, collectionAccount, param.nftIds, param.expiryTs, uint8(newVipLevel));

            // compute max credit for locking cost
            uint96 totalLockingCredit = collectionAccount.totalLockingCredit;
            {
                uint256 creditBuffer;
                unchecked {
                    creditBuffer = totalCredit - totalLockingCredit;
                }
                if (totalCreditCost > creditBuffer || totalCreditCost > param.maxCreditCost) {
                    revert Errors.InsufficientCredit();
                }
            }

            // update user vip key counts
            for (uint256 vipLevel = 0; vipLevel < vipLevelDiffs.length;) {
                userAccount.updateVipKeyCount(uint8(vipLevel), vipLevelDiffs[vipLevel]);
                unchecked {
                    ++vipLevel;
                }
            }

            totalLockingCredit += totalCreditCost.toUint96();
            collectionAccount.totalLockingCredit = totalLockingCredit;
            if (totalLockingCredit > minMaintCredit) {
                userAccount.minMaintCredit = totalLockingCredit;
                minMaintCredit = totalLockingCredit;
            }
        }

        emit ExtendKey(msg.sender, param.collection, param.nftIds, safeBoxKeys, param.expiryTs, minMaintCredit);
    }

    function _extendLockingForKeys(
        CollectionState storage collectionState,
        CollectionAccount storage userCollectionAccount,
        uint256[] memory nftIds,
        uint256 newExpiryTs, // expiryTs of 0 is infinite.
        uint8 newVipLevel
    ) private returns (int256[] memory, uint256, uint256[] memory) {
        LockInfo memory info = LockInfo({
            isInfinite: newExpiryTs == 0,
            currentBucket: Helper.counterStamp(block.timestamp),
            newExpiryBucket: Helper.counterStamp(newExpiryTs),
            totalManaged: collectionState.activeSafeBoxCnt + collectionState.freeTokenIds.length,
            newRequireLockCredit: 0,
            infiniteCnt: collectionState.infiniteCnt
        });
        if (info.isInfinite) {
            info.newExpiryBucket = Helper.counterStamp(block.timestamp + Constants.MAX_LOCKING_PERIOD);
        }

        uint256[] memory buckets = Helper.prepareBucketUpdate(collectionState, info.currentBucket, info.newExpiryBucket);
        int256[] memory vipLevelDiffs = new int256[](Constants.VIP_LEVEL_COUNT);
        /// @dev `keys` used to log info, we just compact its fields into one 256 bits number
        uint256[] memory keys = new uint256[](nftIds.length);

        for (uint256 idx; idx < nftIds.length;) {
            if (Helper.hasActiveActivities(collectionState, nftIds[idx])) revert Errors.NftHasActiveActivities();

            (SafeBox storage safeBox, SafeBoxKey storage safeBoxKey) =
                Helper.useSafeBoxAndKey(collectionState, userCollectionAccount, nftIds[idx]);

            {
                uint256 extendOffset = Helper.counterStamp(safeBox.expiryTs) - info.currentBucket;
                unchecked {
                    for (uint256 i; i < extendOffset; ++i) {
                        if (buckets[i] == 0) revert Errors.InvalidParam();
                        --buckets[i];
                    }
                }
            }

            uint256 safeboxQuote = updateCountersAndGetSafeboxCredit(buckets, info, newVipLevel);

            if (safeboxQuote > safeBoxKey.lockingCredit) {
                info.newRequireLockCredit += (safeboxQuote - safeBoxKey.lockingCredit);
                safeBoxKey.lockingCredit = safeboxQuote.toUint96();
            }

            uint8 oldVipLevel = safeBoxKey.vipLevel;
            if (newVipLevel > oldVipLevel) {
                safeBoxKey.vipLevel = newVipLevel;
                --vipLevelDiffs[oldVipLevel];
                ++vipLevelDiffs[newVipLevel];
            }

            if (info.isInfinite) {
                safeBox.expiryTs = 0;
                ++info.infiniteCnt;
            } else {
                safeBox.expiryTs = uint32(newExpiryTs);
            }

            keys[idx] = SafeBoxLib.encodeSafeBoxKey(safeBoxKey);

            unchecked {
                ++idx;
            }
        }

        if (info.isInfinite) {
            collectionState.infiniteCnt = info.infiniteCnt;
        } else {
            collectionState.countingBuckets.batchSet(info.currentBucket, buckets);
            if (info.newExpiryBucket > collectionState.lastUpdatedBucket) {
                collectionState.lastUpdatedBucket = uint64(info.newExpiryBucket);
            }
        }
        return (vipLevelDiffs, info.newRequireLockCredit, keys);
    }

    function updateCountersAndGetSafeboxCredit(uint256[] memory counters, LockInfo memory lockInfo, uint8 vipLevel)
        private
        pure
        returns (uint256 result)
    {
        unchecked {
            uint256 infiniteCnt = lockInfo.infiniteCnt;
            uint256 totalManaged = lockInfo.totalManaged;

            uint256 counterOffsetEnd = (counters.length + 1) * 0x20;
            uint256 tmpCount;
            if (lockInfo.isInfinite) {
                for (uint256 i = 0x20; i < counterOffsetEnd; i += 0x20) {
                    assembly {
                        tmpCount := mload(add(counters, i))
                    }
                    result += Constants.getRequiredStakingForLockRatio(infiniteCnt + tmpCount, totalManaged);
                }
                /// infinite lock need more staking
                result +=
                    Constants.getRequiredStakingForLockRatio(infiniteCnt, totalManaged) * Constants.MAX_LOCKING_BUCKET;
            } else {
                for (uint256 i = 0x20; i < counterOffsetEnd; i += 0x20) {
                    assembly {
                        tmpCount := mload(add(counters, i))
                    }
                    result += Constants.getRequiredStakingForLockRatio(infiniteCnt + tmpCount, totalManaged);
                    assembly {
                        /// increase counters[i]
                        mstore(add(counters, i), add(tmpCount, 1))
                    }
                }
            }
            result = Constants.getVipRequiredStakingWithDiscount(result, vipLevel);
        }
    }

    function removeExpiredKeysAndRestoreCredits(
        CollectionState storage collectionState,
        UserFloorAccount storage userAccount,
        address collectionId,
        uint256[] memory nftIds,
        address onBehalfOf
    ) public returns (uint256 releasedCredit) {
        CollectionAccount storage collectionAccount = userAccount.getByKey(collectionId);

        uint256 removedCnt;
        uint256[] memory removedIds = new uint256[](nftIds.length);
        uint256[] memory removedKeys = new uint256[](nftIds.length);
        for (uint256 i = 0; i < nftIds.length;) {
            uint256 nftId = nftIds[i];
            SafeBoxKey memory safeBoxKey = collectionAccount.getByKey(nftId);
            SafeBox memory safeBox = collectionState.safeBoxes[nftId];

            if (safeBoxKey.keyId == 0) {
                revert Errors.InvalidParam();
            }

            if (safeBox._isSafeBoxExpired() || !safeBox._isKeyMatchingSafeBox(safeBoxKey)) {
                removedIds[removedCnt] = nftId;
                removedKeys[removedCnt] = SafeBoxLib.encodeSafeBoxKey(safeBoxKey);

                unchecked {
                    ++removedCnt;
                    releasedCredit += safeBoxKey.lockingCredit;
                }

                userAccount.updateVipKeyCount(safeBoxKey.vipLevel, -1);
                collectionAccount.removeSafeboxKey(nftId);
            }

            unchecked {
                ++i;
            }
        }

        if (releasedCredit > 0) {
            collectionAccount.totalLockingCredit -= releasedCredit.toUint96();
        }

        emit RemoveExpiredKey(msg.sender, onBehalfOf, collectionId, removedIds, removedKeys);
    }

    function claimRandomNFT(
        CollectionState storage collection,
        mapping(address => UserFloorAccount) storage userAccounts,
        address creditToken,
        address collectionId,
        uint256 claimCnt,
        uint256 maxCreditCost,
        address receiver
    ) public returns (uint256 totalCreditCost) {
        if (claimCnt == 0 || collection.freeTokenIds.length < claimCnt) revert Errors.ClaimableNftInsufficient();

        uint256 currentlyLocked = getActiveSafeBoxes(collection, block.timestamp) + collection.infiniteCnt;
        uint256 totalManaged = collection.activeSafeBoxCnt + collection.freeTokenIds.length;

        uint256[] memory selectedTokenIds = new uint256[](claimCnt);

        UserFloorAccount storage userAccount = userAccounts[msg.sender];
        uint8 vipLevel = Constants.getVipLevel(userAccount.tokenBalance(creditToken));
        while (claimCnt > 0) {
            totalCreditCost += Constants.getClaimRandomCost(currentlyLocked, totalManaged, vipLevel);

            /// just compute a deterministic random number
            uint256 chosenNftIdx = uint256(keccak256(abi.encodePacked(block.timestamp, block.prevrandao, totalManaged)))
                % collection.freeTokenIds.length;

            unchecked {
                --claimCnt;
                --totalManaged;
            }

            selectedTokenIds[claimCnt] = collection.freeTokenIds[chosenNftIdx];

            collection.freeTokenIds[chosenNftIdx] = collection.freeTokenIds[collection.freeTokenIds.length - 1];
            collection.freeTokenIds.pop();
        }

        if (totalCreditCost > maxCreditCost) {
            revert Errors.InsufficientCredit();
        }

        userAccount.transferToken(userAccounts[address(this)], creditToken, totalCreditCost, true);
        collection.floorToken.burn(msg.sender, Constants.FLOOR_TOKEN_AMOUNT * selectedTokenIds.length);
        ERC721Transfer.safeBatchTransferFrom(collectionId, address(this), receiver, selectedTokenIds);

        emit ClaimRandomNft(msg.sender, receiver, collectionId, selectedTokenIds, totalCreditCost);
    }

    function getActiveSafeBoxes(CollectionState storage collectionState, uint256 timestamp)
        internal
        view
        returns (uint256)
    {
        uint256 bucketStamp = Helper.counterStamp(timestamp);
        if (collectionState.lastUpdatedBucket < bucketStamp) {
            return 0;
        }
        return collectionState.countingBuckets.get(bucketStamp);
    }

    function addSafeBox(CollectionState storage collectionState, uint256 nftId, SafeBox memory safebox) internal {
        if (collectionState.safeBoxes[nftId].keyId > 0) revert Errors.SafeBoxAlreadyExist();
        collectionState.safeBoxes[nftId] = safebox;
        ++collectionState.activeSafeBoxCnt;
    }

    function removeSafeBox(CollectionState storage collectionState, uint256 nftId) internal {
        delete collectionState.safeBoxes[nftId];
        --collectionState.activeSafeBoxCnt;
    }
}