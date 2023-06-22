// SPDX-License-Identifier: MIT
// Copyright 2023 PROOF Holdings Inc
pragma solidity ^0.8.16;

import {AccessControlEnumerable} from "ethier/utils/AccessControlEnumerable.sol";
import {ISellable, ImmutableSellableCallbacker, SettableSellableCallbacker} from "../base/SellableCallbacker.sol";

/**
 * @notice Base contract for seller presets that call back to a sellable contract.
 */
contract AccessControlled is AccessControlEnumerable {
    constructor(address admin, address steerer) {
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(DEFAULT_STEERING_ROLE, steerer);
    }
}

/**
 * @notice Base contract for seller presets that call back to a sellable contract.
 */
contract CallbackerWithAccessControl is ImmutableSellableCallbacker, AccessControlled {
    constructor(address admin, address steerer, ISellable sellable_)
        ImmutableSellableCallbacker(sellable_)
        AccessControlled(admin, steerer)
    {}
}

/**
 * @notice Base contract for seller presets that call back to a sellable contract.
 */
contract SettableCallbackerWithAccessControl is SettableSellableCallbacker, AccessControlled {
    constructor(address admin, address steerer) AccessControlled(admin, steerer) {}

    function setSellable(ISellable sellable_) external onlyRole(DEFAULT_STEERING_ROLE) {
        _setSellable(sellable_);
    }
}