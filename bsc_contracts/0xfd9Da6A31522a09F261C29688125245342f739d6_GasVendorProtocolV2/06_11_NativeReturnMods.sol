// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;

import {NativeClaimer} from "./NativeClaimer.sol";
import {TokenHelper} from "./TokenHelper.sol";

abstract contract NativeReturnMods {
    using NativeClaimer for NativeClaimer.State;

    modifier returnUnclaimedNative(NativeClaimer.State memory claimer_) {
        require(claimer_.claimed() == 0, "NR: claimer already in use");
        _;
        TokenHelper.transferFromThis(TokenHelper.NATIVE_TOKEN, msg.sender, claimer_.unclaimed());
    }
}