// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import { BitMaps } from "../libraries/BitMaps.sol";
import { Helper } from "../libraries/Helper.sol";

error Lockable__Locked();

abstract contract Lockable {
    using Helper for address;
    using BitMaps for BitMaps.BitMap;

    BitMaps.BitMap private _isLocked;

    function isLocked(address account) external view returns (bool) {
        return _isLocked.get(account.toUint256());
    }

    function _notLocked(address sender_, address from_, address to_) internal view virtual {
        if (_isLocked.get(sender_.toUint256()) || _isLocked.get(from_.toUint256()) || _isLocked.get(to_.toUint256())) revert Lockable__Locked();
    }

    function _setLockUser(address account_, bool status_) internal {
        uint256 account = account_.toUint256();
        _isLocked.setTo(account, status_);
    }

    uint256[49] private __gap;
}