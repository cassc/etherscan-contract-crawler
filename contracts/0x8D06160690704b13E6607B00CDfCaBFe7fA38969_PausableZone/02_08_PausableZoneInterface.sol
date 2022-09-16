// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import { CsportInterface } from "../../interfaces/CsportInterface.sol";

import {
    AdvancedOrder,
    CriteriaResolver,
    Order,
    OrderComponents,
    Fulfillment,
    Execution
} from "../../lib/ConsiderationStructs.sol";

/**
 * @title  PausableZone
 * @author Csport dev
 * @notice PausableZone is a simple zone implementation that approves every
 *         order. It can be self-destructed by its controller to pause
 *         restricted orders that have it set as their zone.
 */
interface PausableZoneInterface {
    /**
     * @notice Cancel an arbitrary number of orders that have agreed to use the
     *         contract as their zone.
     *
     * @param csport  The Csport address.
     * @param orders   The orders to cancel.
     *
     * @return cancelled A boolean indicating whether the supplied orders have
     *                   been successfully cancelled.
     */
    function cancelOrders(
        CsportInterface csport,
        OrderComponents[] calldata orders
    ) external returns (bool cancelled);

    /**
     * @notice Execute an arbitrary number of matched orders, each with
     *         an arbitrary number of items for offer and consideration
     *         along with a set of fulfillments allocating offer components
     *         to consideration components.
     *
     * @param csport      The Csport address.
     * @param orders       The orders to match.
     * @param fulfillments An array of elements allocating offer components
     *                     to consideration components.
     *
     * @return executions An array of elements indicating the sequence of
     *                    transfers performed as part of matching the given
     *                    orders.
     */
    function executeMatchOrders(
        CsportInterface csport,
        Order[] calldata orders,
        Fulfillment[] calldata fulfillments
    ) external payable returns (Execution[] memory executions);

    /**
     * @notice Execute an arbitrary number of matched advanced orders,
     *         each with an arbitrary number of items for offer and
     *         consideration along with a set of fulfillments allocating
     *         offer components to consideration components.
     *
     * @param csport           The Csport address.
     * @param orders            The orders to match.
     * @param criteriaResolvers An array where each element contains a reference
     *                          to a specific order as well as that order's
     *                          offer or consideration, a token identifier, and
     *                          a proof that the supplied token identifier is
     *                          contained in the order's merkle root.
     * @param fulfillments      An array of elements allocating offer components
     *                          to consideration components.
     *
     * @return executions An array of elements indicating the sequence of
     *                    transfers performed as part of matching the given
     *                    orders.
     */
    function executeMatchAdvancedOrders(
        CsportInterface csport,
        AdvancedOrder[] calldata orders,
        CriteriaResolver[] calldata criteriaResolvers,
        Fulfillment[] calldata fulfillments
    ) external payable returns (Execution[] memory executions);

    /**
     * @notice Pause this contract, safely stopping orders from using
     *         the contract as a zone. Restricted orders with this address as a
     *         zone will not be fulfillable unless the zone is redeployed to the
     *         same address.
     */
    function pause(address payee) external;

    /**
     * @notice Assign the given address with the ability to operate the zone.
     *
     * @param operatorToAssign The address to assign as the operator.
     */
    function assignOperator(address operatorToAssign) external;
}