// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {NativeReceiver} from "../asset/NativeReceiver.sol";
import {SimpleInitializable} from "../misc/SimpleInitializable.sol";
import {Withdrawable} from "../withdraw/Withdrawable.sol";

contract Delegate is SimpleInitializable, Ownable, Withdrawable, NativeReceiver {
    constructor() {
        _initializeWithSender();
    }

    function _initialize() internal override {
        _transferOwnership(initializer());
    }

    function setOwner(address newOwner_) external whenInitialized onlyInitializer {
        _transferOwnership(newOwner_);
    }

    function _checkWithdraw() internal view override {
        _ensureInitialized();
        _checkOwner();
    }
}