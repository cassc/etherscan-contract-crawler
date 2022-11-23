// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.16;

import {IInitializable} from "./IInitializable.sol";
import {InitializableStorage} from "./InitializableStorage.sol";

abstract contract Initializable is IInitializable, InitializableStorage {
    // prettier-ignore
    constructor(bytes32 initializerSlot_)
        InitializableStorage(initializerSlot_)
    {} // solhint-disable-line no-empty-blocks

    modifier whenInitialized() {
        _ensureInitialized();
        _;
    }

    modifier whenNotInitialized() {
        _ensureNotInitialized();
        _;
    }

    modifier init() {
        _ensureNotInitialized();
        _initializeWithSender();
        _;
    }

    modifier onlyInitializer() {
        require(msg.sender == initializer(), "IN: sender not initializer");
        _;
    }

    function initialized() public view returns (bool) {
        return initializer() != address(0);
    }

    function initializer() public view returns (address) {
        return _initializer();
    }

    function _ensureInitialized() internal view {
        require(initialized(), "IN: not initialized");
    }

    function _ensureNotInitialized() internal view {
        require(!initialized(), "IN: already initialized");
    }

    function _initializeWithSender() internal {
        _setInitializer(msg.sender);
    }
}