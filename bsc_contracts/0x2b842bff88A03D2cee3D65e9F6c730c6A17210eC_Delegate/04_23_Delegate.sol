// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.16;

import {Ownable} from "../../lib/Ownable.sol";

import {TokenHelper} from "../asset/TokenHelper.sol";
import {NativeReceiver} from "../asset/NativeReceiver.sol";

import {SimpleInitializable} from "../init/SimpleInitializable.sol";

import {IWithdrawable} from "../withdraw/IWithdrawable.sol";
import {Withdrawable, Withdraw} from "../withdraw/Withdrawable.sol";

import {IDelegate} from "./IDelegate.sol";

contract Delegate is IDelegate, SimpleInitializable, Ownable, Withdrawable, NativeReceiver {
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