// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.16;

import {StorageSlot} from "../../lib/StorageSlot.sol";

import {TokenHelper} from "../asset/TokenHelper.sol";

import {IAccountWhitelist} from "../whitelist/IAccountWhitelist.sol";

import {Withdrawable} from "./Withdrawable.sol";

abstract contract WhitelistWithdrawableStorage {
    bytes32 private immutable _withdrawWhitelistSlot;

    constructor(bytes32 withdrawWhitelistSlot_) {
        _withdrawWhitelistSlot = withdrawWhitelistSlot_;
    }

    function _withdrawWhitelistStorage() private view returns (StorageSlot.AddressSlot storage) {
        return StorageSlot.getAddressSlot(_withdrawWhitelistSlot);
    }

    function _withdrawWhitelist() internal view returns (IAccountWhitelist) {
        return IAccountWhitelist(_withdrawWhitelistStorage().value);
    }

    function _setWithdrawWhitelist(address withdrawWhitelist_) internal {
        _withdrawWhitelistStorage().value = withdrawWhitelist_;
    }
}