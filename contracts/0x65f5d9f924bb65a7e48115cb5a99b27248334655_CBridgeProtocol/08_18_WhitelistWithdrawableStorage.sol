// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

import "./StorageSlot.sol";

import "./TokenHelper.sol";

import "./IAccountWhitelist.sol";

import "./Withdrawable.sol";

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