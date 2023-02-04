// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

import "./Withdrawable.sol";

import "./WhitelistWithdrawableStorage.sol";

abstract contract WhitelistWithdrawable is Withdrawable, WhitelistWithdrawableStorage {
    constructor(
        bytes32 withdrawWhitelistSlot_,
        address withdrawWhitelist_
    ) WhitelistWithdrawableStorage(withdrawWhitelistSlot_) {
        _initialize(withdrawWhitelist_);
    }

    function initializeWhitelistWithdrawable(address withdrawWhitelist_) internal {
        _initialize(withdrawWhitelist_);
    }

    function _initialize(address withdrawWhitelist_) private {
        require(withdrawWhitelist_ != address(0), "WW: zero withdraw whitelist");
        _setWithdrawWhitelist(withdrawWhitelist_);
    }

    function _checkWithdraw() internal view override {
        _checkWithdrawerWhitelisted();
    }

    function _checkWithdrawerWhitelisted() private view {
        require(_withdrawWhitelist().isAccountWhitelisted(msg.sender), "WW: withdrawer not whitelisted");
    }
}