// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;

import {Withdrawable} from "./Withdrawable.sol";
import {AccountWhitelist} from "../whitelist/AccountWhitelist.sol";

abstract contract WhitelistWithdrawable is Withdrawable {
    address private immutable _withdrawWhitelist;

    constructor(address withdrawWhitelist_) {
        _withdrawWhitelist = withdrawWhitelist_;
    }

    function _checkWithdraw() internal view override {
        require(AccountWhitelist(_withdrawWhitelist).isAccountWhitelisted(msg.sender), "WW: withdrawer not whitelisted");
    }
}