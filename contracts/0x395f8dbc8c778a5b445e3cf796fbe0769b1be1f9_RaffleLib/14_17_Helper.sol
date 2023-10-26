// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "../Constants.sol";
import "../Errors.sol";
import "./SafeBox.sol";
import "./User.sol";
import {SafeBox, CollectionState, AuctionInfo, CollectionAccount, SafeBoxKey} from "./Structs.sol";
import "../library/RollingBuckets.sol";

library Helper {
    using SafeBoxLib for SafeBox;
    using UserLib for CollectionAccount;
    using RollingBuckets for mapping(uint256 => uint256);

    function counterStamp(uint256 timestamp) internal pure returns (uint96) {
        unchecked {
            return uint96((timestamp + Constants.BUCKET_SPAN_1) / Constants.BUCKET_SPAN);
        }
    }

    function ensureProxyVipLevel(uint8 vipLevel, bool proxy) internal pure {
        if (proxy && vipLevel < Constants.PROXY_COLLECTION_VIP_THRESHOLD) {
            revert Errors.InvalidParam();
        }
    }

    function ensureMaxLocking(uint8 vipLevel, uint256 requireExpiryTs) internal view {
        /// vip level 0 can not use safebox utilities.
        if (vipLevel >= Constants.VIP_LEVEL_COUNT || vipLevel == 0) {
            revert Errors.InvalidParam();
        }

        /// only check when it is not infinite lock
        if (requireExpiryTs > 0) {
            uint256 deltaBucket;
            unchecked {
                deltaBucket = counterStamp(requireExpiryTs) - counterStamp(block.timestamp);
            }
            if (deltaBucket == 0 || deltaBucket > Constants.getVipLockingBuckets(vipLevel)) {
                revert Errors.InvalidParam();
            }
        } else if (vipLevel < Constants.VIP_LEVEL_COUNT - 1) {
            revert Errors.InvalidParam();
        }
    }

    function useSafeBoxAndKey(CollectionState storage collection, CollectionAccount storage userAccount, uint256 nftId)
        internal
        view
        returns (SafeBox storage safeBox, SafeBoxKey storage key)
    {
        safeBox = collection.safeBoxes[nftId];
        if (safeBox.keyId == 0) revert Errors.SafeBoxNotExist();
        if (safeBox.isSafeBoxExpired()) revert Errors.SafeBoxHasExpire();

        key = userAccount.getByKey(nftId);
        if (!safeBox.isKeyMatchingSafeBox(key)) revert Errors.NoMatchingSafeBoxKey();
    }

    function useSafeBox(CollectionState storage collection, uint256 nftId)
        internal
        view
        returns (SafeBox storage safeBox)
    {
        safeBox = collection.safeBoxes[nftId];
        if (safeBox.keyId == 0) revert Errors.SafeBoxNotExist();
    }

    function generateNextKeyId(CollectionState storage collectionState) internal returns (uint64 nextKeyId) {
        nextKeyId = collectionState.nextKeyId;
        ++collectionState.nextKeyId;
    }

    function generateNextActivityId(CollectionState storage collection) internal returns (uint64 nextActivityId) {
        nextActivityId = collection.nextActivityId;
        ++collection.nextActivityId;
    }

    function isAuctionPeriodOver(SafeBox storage safeBox) internal view returns (bool) {
        return safeBox.expiryTs + Constants.FREE_AUCTION_PERIOD < block.timestamp;
    }

    function hasActiveActivities(CollectionState storage collection, uint256 nftId) internal view returns (bool) {
        return hasActiveAuction(collection, nftId) || hasActiveRaffle(collection, nftId)
            || hasActivePrivateOffer(collection, nftId);
    }

    function hasActiveAuction(CollectionState storage collection, uint256 nftId) internal view returns (bool) {
        return collection.activeAuctions[nftId].endTime >= block.timestamp;
    }

    function hasActiveRaffle(CollectionState storage collection, uint256 nftId) internal view returns (bool) {
        return collection.activeRaffles[nftId].endTime >= block.timestamp;
    }

    function hasActivePrivateOffer(CollectionState storage collection, uint256 nftId) internal view returns (bool) {
        return collection.activePrivateOffers[nftId].endTime >= block.timestamp;
    }

    function getTokenFeeRateBips(address creditToken, address floorToken, address settleToken)
        internal
        pure
        returns (uint256)
    {
        uint256 feeRateBips = Constants.COMMON_FEE_RATE_BIPS;
        if (settleToken == creditToken) {
            feeRateBips = Constants.CREDIT_FEE_RATE_BIPS;
        } else if (settleToken == floorToken) {
            feeRateBips = Constants.SPEC_FEE_RATE_BIPS;
        }

        return feeRateBips;
    }

    function calculateActivityFee(uint256 settleAmount, uint256 feeRateBips)
        internal
        pure
        returns (uint256 afterFee, uint256 fee)
    {
        fee = settleAmount * feeRateBips / 10000;
        unchecked {
            afterFee = settleAmount - fee;
        }
    }

    function prepareBucketUpdate(CollectionState storage collection, uint256 startBucket, uint256 endBucket)
        internal
        view
        returns (uint256[] memory buckets)
    {
        uint256 validEnd = collection.lastUpdatedBucket;
        uint256 padding;
        if (endBucket < validEnd) {
            validEnd = endBucket;
        } else {
            unchecked {
                padding = endBucket - validEnd;
            }
        }

        if (startBucket < validEnd) {
            if (padding == 0) {
                buckets = collection.countingBuckets.batchGet(startBucket, validEnd);
            } else {
                uint256 validLen;
                unchecked {
                    validLen = validEnd - startBucket;
                }
                buckets = new uint256[](validLen + padding);
                uint256[] memory tmp = collection.countingBuckets.batchGet(startBucket, validEnd);
                for (uint256 i; i < validLen;) {
                    buckets[i] = tmp[i];
                    unchecked {
                        ++i;
                    }
                }
            }
        } else {
            buckets = new uint256[](endBucket - startBucket);
        }
    }
}