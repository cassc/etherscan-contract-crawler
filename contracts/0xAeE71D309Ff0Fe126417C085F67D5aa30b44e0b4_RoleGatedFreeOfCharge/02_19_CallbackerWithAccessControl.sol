// SPDX-License-Identifier: MIT
// Copyright 2023 PROOF Holdings Inc
pragma solidity ^0.8.16;

import {AccessControlEnumerable} from "ethier/utils/AccessControlEnumerable.sol";
import {ISellable, SellableCallbacker} from "../base/SellableCallbacker.sol";

/**
 * @notice Base contract for seller presets that call back to a sellable contract.
 */
contract CallbackerWithAccessControl is SellableCallbacker, AccessControlEnumerable {
    constructor(address admin, address steerer, ISellable sellable_) SellableCallbacker(sellable_) {
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(DEFAULT_STEERING_ROLE, steerer);
    }
}