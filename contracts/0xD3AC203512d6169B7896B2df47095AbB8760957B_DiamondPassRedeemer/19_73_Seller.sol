// SPDX-License-Identifier: MIT
// Copyright 2023 PROOF Holdings Inc
pragma solidity >=0.8.0 <0.9.0;

import {ReentrancyGuard} from "openzeppelin-contracts/security/ReentrancyGuard.sol";
import {PurchaseExecuter} from "../interfaces/PurchaseExecuter.sol";

/**
 * @notice Abstract base contract for all `Seller`s.
 * @dev The intention of this contract is to provide an extensible base for various kinds of Seller modules that can be
 * flexibly composed to build more complex sellers - allowing effective code reuse.
 * Derived contracts are intended to implement their logic by overriding and extending the `_checkAndModifyPurchase` and
 * `_beforePurchase` hooks (calling the parent implementation(s) to compose logic). The former is intended to perform
 * manipulations and checks of the input data; the latter to update the internal state of the module.
 * Final sellers will compose these modules and expose an addition external purchase function for buyers.
 */

abstract contract Seller is PurchaseExecuter, ReentrancyGuard {
    uint256 internal constant _UNDEFINED_COST = type(uint256).max;

    /**
     * @notice Internal function handling a given purchase, performing checks and input manipulations depending on the
     * logic in the hooks.
     * @param to The receiver of the purchase
     * @param num Number of requested purchases
     * @param externalTotalCost Total cost of the purchase
     * @dev This function is intended to be wrapped in an external method for final sellers. Since we cannot foresee
     * what logic will be implemented in the hooks, we added a reentrancy guard for safety.
     */
    function _purchase(address to, uint64 num, uint256 externalTotalCost, bytes memory data)
        internal
        virtual
        nonReentrant
    {
        uint256 totalCost;
        (to, num, totalCost) = _checkAndModifyPurchase(to, num, externalTotalCost, data);
        _beforePurchase(to, num, totalCost, data);
        _executePurchase(to, num, totalCost, data);
    }

    // =================================================================================================================
    //                           Hooks
    // =================================================================================================================

    /**
     * @notice Hook that is called before handling a purchase (even before `_beforePurchase`)
     * @dev The intent of this hook is to manipulate the input data and perform  checks before actually handling the
     * purchase.
     * @param to The receiver of the purchase
     * @param num Number of requested purchases
     * @param totalCost Total cost of the purchase
     * @dev This function MUST return sensible values, since these will be used to perfom the purchase.
     */
    function _checkAndModifyPurchase(address to, uint64 num, uint256 totalCost, bytes memory)
        internal
        view
        virtual
        returns (address, uint64, uint256)
    {
        return (to, num, totalCost);
    }

    /**
     * @notice Hook that is called before handling a purchase.
     * @dev The intent of this hook is to update the internal state of the seller (module) if necessary.
     * It is critical that the updates happen here and not in `_checkAndModifyPurchase` because only after calling that
     * function the purchase parameters can be considered fixed.
     */
    function _beforePurchase(address to, uint64 num, uint256 totalCost, bytes memory data) internal virtual {
        // solhint-disable-line no-empty-blocks
    }
}