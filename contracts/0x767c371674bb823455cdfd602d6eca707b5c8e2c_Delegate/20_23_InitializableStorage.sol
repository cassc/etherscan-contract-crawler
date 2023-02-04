// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.16;

import "./StorageSlot.sol";

abstract contract InitializableStorage {
    bytes32 private immutable _initializerSlot;

    constructor(bytes32 initializerSlot_) {
        _initializerSlot = initializerSlot_;
    }

    function _initializerStorage() private view returns (StorageSlot.AddressSlot storage) {
        return StorageSlot.getAddressSlot(_initializerSlot);
    }

    function _initializer() internal view returns (address) {
        return _initializerStorage().value;
    }

    function _setInitializer(address initializer_) internal {
        _initializerStorage().value = initializer_;
    }
}