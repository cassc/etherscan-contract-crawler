// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {SafeBox, SafeBoxKey} from "./Structs.sol";

library SafeBoxLib {
    uint64 public constant SAFEBOX_KEY_NOTATION = type(uint64).max;

    function isInfiniteSafeBox(SafeBox storage safeBox) internal view returns (bool) {
        return safeBox.expiryTs == 0;
    }

    function isSafeBoxExpired(SafeBox storage safeBox) internal view returns (bool) {
        return safeBox.expiryTs != 0 && safeBox.expiryTs < block.timestamp;
    }

    function _isSafeBoxExpired(SafeBox memory safeBox) internal view returns (bool) {
        return safeBox.expiryTs != 0 && safeBox.expiryTs < block.timestamp;
    }

    function isKeyMatchingSafeBox(SafeBox storage safeBox, SafeBoxKey storage safeBoxKey)
        internal
        view
        returns (bool)
    {
        return safeBox.keyId == safeBoxKey.keyId;
    }

    function _isKeyMatchingSafeBox(SafeBox memory safeBox, SafeBoxKey memory safeBoxKey) internal pure returns (bool) {
        return safeBox.keyId == safeBoxKey.keyId;
    }

    function encodeSafeBoxKey(SafeBoxKey memory key) internal pure returns (uint256) {
        uint256 val = key.lockingCredit;
        val |= (uint256(key.keyId) << 96);
        val |= (uint256(key.vipLevel) << 160);
        return val;
    }
}