// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "openzeppelin-contracts/contracts/utils/math/SafeCast.sol";

import "../Constants.sol";
import "../Errors.sol";
import {UserFloorAccount, CollectionAccount, SafeBoxKey} from "./Structs.sol";

library UserLib {
    using SafeCast for uint256;

    /// @notice update the account maintain credit on behalfOf `onBehalfOf`
    event UpdateMaintainCredit(address indexed onBehalfOf, uint256 minMaintCredit);

    address internal constant LIST_GUARD = address(1);

    function ensureVipCredit(UserFloorAccount storage account, uint8 requireVipLevel, address creditToken)
        internal
        view
        returns (uint256)
    {
        uint256 totalCredit = tokenBalance(account, creditToken);
        if (Constants.getVipBalanceRequirements(requireVipLevel) > totalCredit) {
            revert Errors.InsufficientBalanceForVipLevel();
        }
        return totalCredit;
    }

    function getMinMaintVipLevel(UserFloorAccount storage account) internal view returns (uint8) {
        unchecked {
            return uint8(account.vipInfo >> 240);
        }
    }

    function getMinLevelAndVipKeyCounts(uint256 vipInfo)
        internal
        pure
        returns (uint8 minLevel, uint256[] memory counts)
    {
        unchecked {
            counts = new uint256[](Constants.VIP_LEVEL_COUNT);
            minLevel = uint8(vipInfo >> 240);
            for (uint256 i; i < Constants.VIP_LEVEL_COUNT; ++i) {
                counts[i] = (vipInfo >> (i * 24)) & 0xFFFFFF;
            }
        }
    }

    function storeMinLevelAndVipKeyCounts(
        UserFloorAccount storage account,
        uint8 minMaintVipLevel,
        uint256[] memory keyCounts
    ) internal {
        unchecked {
            uint256 _data = (uint256(minMaintVipLevel) << 240);
            for (uint256 i; i < Constants.VIP_LEVEL_COUNT; ++i) {
                _data |= ((keyCounts[i] & 0xFFFFFF) << (i * 24));
            }
            account.vipInfo = _data;
        }
    }

    function getOrAddCollection(UserFloorAccount storage user, address collection)
        internal
        returns (CollectionAccount storage)
    {
        CollectionAccount storage entry = user.accounts[collection];
        if (entry.next == address(0)) {
            if (user.firstCollection == address(0)) {
                user.firstCollection = collection;
                entry.next = LIST_GUARD;
            } else {
                entry.next = user.firstCollection;
                user.firstCollection = collection;
            }
        }
        return entry;
    }

    function removeCollection(UserFloorAccount storage userAccount, address collection, address prev) internal {
        CollectionAccount storage cur = userAccount.accounts[collection];
        if (cur.next == address(0)) revert Errors.InvalidParam();

        if (collection == userAccount.firstCollection) {
            if (cur.next == LIST_GUARD) {
                userAccount.firstCollection = address(0);
            } else {
                userAccount.firstCollection = cur.next;
            }
        } else {
            CollectionAccount storage prevAccount = userAccount.accounts[prev];
            if (prevAccount.next != collection) revert Errors.InvalidParam();
            prevAccount.next = cur.next;
        }

        delete userAccount.accounts[collection];
    }

    function getByKey(UserFloorAccount storage userAccount, address collection)
        internal
        view
        returns (CollectionAccount storage)
    {
        return userAccount.accounts[collection];
    }

    function addSafeboxKey(CollectionAccount storage account, uint256 nftId, SafeBoxKey memory key) internal {
        if (account.keys[nftId].keyId > 0) {
            revert Errors.SafeBoxKeyAlreadyExist();
        }

        account.keys[nftId] = key;
    }

    function removeSafeboxKey(CollectionAccount storage account, uint256 nftId) internal {
        delete account.keys[nftId];
    }

    function getByKey(CollectionAccount storage account, uint256 nftId) internal view returns (SafeBoxKey storage) {
        return account.keys[nftId];
    }

    function tokenBalance(UserFloorAccount storage account, address token) internal view returns (uint256) {
        return account.tokenAmounts[token];
    }

    function lockCredit(UserFloorAccount storage account, uint256 amount) internal {
        unchecked {
            account.lockedCredit += amount;
        }
    }

    function unlockCredit(UserFloorAccount storage account, uint256 amount) internal {
        unchecked {
            account.lockedCredit -= amount;
        }
    }

    function depositToken(UserFloorAccount storage account, address token, uint256 amount) internal {
        account.tokenAmounts[token] += amount;
    }

    function withdrawToken(UserFloorAccount storage account, address token, uint256 amount, bool isCreditToken)
        internal
    {
        uint256 balance = account.tokenAmounts[token];
        if (balance < amount) {
            revert Errors.InsufficientCredit();
        }

        if (isCreditToken) {
            uint256 avaiableBuf;
            unchecked {
                avaiableBuf = balance - amount;
            }
            if (
                avaiableBuf < Constants.getVipBalanceRequirements(getMinMaintVipLevel(account))
                    || avaiableBuf < account.minMaintCredit || avaiableBuf < account.lockedCredit
            ) {
                revert Errors.InsufficientCredit();
            }

            account.tokenAmounts[token] = avaiableBuf;
        } else {
            unchecked {
                account.tokenAmounts[token] = balance - amount;
            }
        }
    }

    function transferToken(
        UserFloorAccount storage from,
        UserFloorAccount storage to,
        address token,
        uint256 amount,
        bool isCreditToken
    ) internal {
        withdrawToken(from, token, amount, isCreditToken);
        depositToken(to, token, amount);
    }

    function updateVipKeyCount(UserFloorAccount storage account, uint8 vipLevel, int256 diff) internal {
        if (vipLevel > 0 && diff != 0) {
            (uint8 minMaintVipLevel, uint256[] memory keyCounts) = getMinLevelAndVipKeyCounts(account.vipInfo);

            if (diff < 0) {
                keyCounts[vipLevel] -= uint256(-diff);
                if (vipLevel == minMaintVipLevel && keyCounts[vipLevel] == 0) {
                    uint8 newVipLevel = vipLevel;
                    do {
                        unchecked {
                            --newVipLevel;
                        }
                    } while (newVipLevel > 0 && keyCounts[newVipLevel] == 0);

                    minMaintVipLevel = newVipLevel;
                }
            } else {
                keyCounts[vipLevel] += uint256(diff);
                if (vipLevel > minMaintVipLevel) {
                    minMaintVipLevel = vipLevel;
                }
            }
            storeMinLevelAndVipKeyCounts(account, minMaintVipLevel, keyCounts);
        }
    }

    function recalculateMinMaintCredit(UserFloorAccount storage account, address onBehalfOf)
        public
        returns (uint256 maxLocking)
    {
        address prev = account.firstCollection;
        for (address collection = account.firstCollection; collection != LIST_GUARD && collection != address(0);) {
            (uint256 locking, address next) =
                (getByKey(account, collection).totalLockingCredit, getByKey(account, collection).next);
            if (locking == 0) {
                removeCollection(account, collection, prev);
                collection = next;
            } else {
                if (locking > maxLocking) {
                    maxLocking = locking;
                }
                prev = collection;
                collection = next;
            }
        }

        account.minMaintCredit = uint96(maxLocking);

        emit UpdateMaintainCredit(onBehalfOf, maxLocking);
    }
}