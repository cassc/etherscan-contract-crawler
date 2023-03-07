// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;

import {StorageSlot} from "@openzeppelin/contracts/utils/StorageSlot.sol";

abstract contract SimpleInitializable {
    function _initializerStorage() private pure returns (StorageSlot.AddressSlot storage) {
        return StorageSlot.getAddressSlot(0x4c943a984a6327bfee4b36cd148236ae13d07c9a3fe7f9857f4809df3e826db1);
    }

    modifier init() {
        _ensureNotInitialized();
        _initializeWithSender();
        _;
    }

    modifier whenInitialized() {
        _ensureInitialized();
        _;
    }

    modifier onlyInitializer() {
        require(msg.sender == initializer(), "SI: sender not initializer");
        _;
    }

    function initializer() public view returns (address) {
        return _initializerStorage().value;
    }

    function initialized() public view returns (bool) {
        return initializer() != address(0);
    }

    function initialize() external init {
        _initialize();
    }

    function _initialize() internal virtual;

    function _initializeWithSender() internal {
        _initializerStorage().value = msg.sender;
    }

    function _ensureInitialized() internal view {
        require(initialized(), "SI: not initialized");
    }

    function _ensureNotInitialized() internal view {
        require(!initialized(), "SI: already initialized");
    }
}