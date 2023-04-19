// SPDX-License-Identifier: MIT
// Copyright (c) 2021 the ethier authors (github.com/divergencetech/ethier)
pragma solidity >=0.8.0 <0.9.0;

import {ISellable, CallbackerWithAccessControl} from "./CallbackerWithAccessControl.sol";
import {FixedSupply} from "../base/SupplyLimited.sol";

/**
 * @notice Seller module that adds a role-gated free-of-charge purchase (e.g. to facilitate to owner mints).
 */
contract RoleGatedFreeOfCharge is CallbackerWithAccessControl, FixedSupply {
    error WrongNumSoldAfterPurchase(uint256 actual, uint256 expected);

    constructor(address admin, address steerer, ISellable sellable_, uint64 numMaxSellable_)
        CallbackerWithAccessControl(admin, steerer, sellable_)
        FixedSupply(numMaxSellable_)
    {
        // solhint-disable-line no-empty-blocks
    }

    /**
     * @notice Encodes a free-of-charge purchase.
     * @param to The address to receive the purchased items.
     * @param num The number of items to purchase.
     */
    struct Receiver {
        address to;
        uint64 num;
    }

    /**
     * @notice Purchases numbers of tokens for given addresses free of charge.
     */
    function _purchase(Receiver[] calldata receivers) internal {
        for (uint256 idx = 0; idx < receivers.length; ++idx) {
            _purchase(receivers[idx].to, receivers[idx].num, 0, "");
        }
    }

    /**
     * @notice Purchases numbers of tokens for given addresses free of charge.
     */
    function purchase(Receiver[] calldata receivers) external onlyRole(DEFAULT_STEERING_ROLE) {
        _purchase(receivers);
    }

    /**
     * @notice Purchases numbers of tokens for given addresses free of charge and checks if the number of sold tokens
     * matches the expected value.
     */
    function purchaseWithGuardRails(Receiver[] calldata receivers, uint256 expectedNumSoldAfter)
        external
        onlyRole(DEFAULT_STEERING_ROLE)
    {
        _purchase(receivers);

        if (numSold() != expectedNumSoldAfter) {
            revert WrongNumSoldAfterPurchase(numSold(), expectedNumSoldAfter);
        }
    }
}