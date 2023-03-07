// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;

import {Swapper} from "./core/swap/Swapper.sol";
import {WhitelistWithdrawable} from "./core/withdraw/WhitelistWithdrawable.sol";
import {LifeControl} from "./core/misc/LifeControl.sol";

struct XSwapConstructorParams {
    address swapSignatureValidator;
    address permitResolverWhitelist;
    address useProtocolWhitelist;
    address delegateManager;
    address withdrawWhitelist;
    address lifeControl;
}

contract XSwap is Swapper, WhitelistWithdrawable {
    address private immutable _lifeControl;

    constructor(XSwapConstructorParams memory params_)
        WhitelistWithdrawable(params_.withdrawWhitelist)
        Swapper(params_.swapSignatureValidator, params_.permitResolverWhitelist, params_.useProtocolWhitelist, params_.delegateManager) {
        _lifeControl = params_.lifeControl;
    }

    function _checkSwapEnabled() internal view override {
        require(!LifeControl(_lifeControl).paused(), "XS: swapping paused");
    }
}