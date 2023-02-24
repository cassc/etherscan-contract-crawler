// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {Context} from "../oz/utils/Context.sol";

import {IBlacklistable} from "./interfaces/IBlacklistable.sol";

import {BitMaps} from "../oz/utils/structs/BitMaps.sol";
import {Bytes32Address} from "../libraries/Bytes32Address.sol";

/**
 * @title Blacklistable
 * @dev Abstract contract that provides blacklist functionality.
 * Users of this contract can add or remove an address from the blacklist.
 * Users can check if an address is blacklisted.
 */
abstract contract Blacklistable is Context, IBlacklistable {
    using Bytes32Address for address;
    using BitMaps for BitMaps.BitMap;

    BitMaps.BitMap private __blacklisted;

    /// @inheritdoc IBlacklistable
    function isBlacklisted(
        address account_
    ) public view virtual returns (bool) {
        return __blacklisted.get(account_.fillLast96Bits());
    }

    function areBlacklisted(
        address[] calldata accounts_
    ) public view virtual returns (bool) {
        uint256 length = accounts_.length;
        for (uint256 i; i < length; ) {
            if (__blacklisted.get(accounts_[i].fillLast96Bits())) return true;
            unchecked {
                ++i;
            }
        }

        return false;
    }

    /**
     * @dev Internal function to set the status of an account.
     * @param account_ The address to change the status of.
     * @param status_ The new status for the address. True for blacklisted, false for not blacklisted.
     */
    function _setUserStatus(address account_, bool status_) internal virtual {
        __blacklisted.setTo(account_.fillLast96Bits(), status_);
        emit UserStatusSet(_msgSender(), account_, status_);
    }
}