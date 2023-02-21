// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {
    OrderComponents,
    AdvancedOrder,
    CriteriaResolver
} from "../../lib/ConsiderationStructs.sol";
import { MembersOnlyExtraData } from "../../lib/CietyZoneStructs.sol";

import "../../interfaces/SeaportZoneInterface.sol";
import "../../interfaces/CietyZoneInterface.sol";
import "../../interfaces/SeaportInterface.sol";
import "../../lib/CietyZoneSignatureUtils.sol";

/*
 * @title MembersOnlyZone
 * @author ddevkim, ne2030
 * @notice MembersOnlyZone contains logics to realize when an order can be only transacted by DAO members on CIETY dapp.
                           The members only order can only be trasacted by operator's signature which is transferred
                           by extradata in transaction arguments with a valid deadline.
                           A signature contains a deadline, a member executioner, and an orderHash signed with EIP-712 to prevent forgery.
                           The deadline functions to prevent a signature from being used by a DAO member who leaves
                           by enforcing that the signature is only valid for a short period of time.

                           MembersOnlyZone can effectively block the following abusing tries.
                           - Signatures cannot be hijacked and abused by other members. (caller is not order fulfiller(member) in signature)
                           - Cannot be used if the member is dismissed (if the member is dismissed, the signature cannot be received again,
                             and the signature received when the member was a member will be invalidated by dealine after a few minutes).
                           - Cannot be used to execute a different order created on another Dao. (different orderHash in signature)
 */

contract MembersOnlyZone is
    SeaportZoneInterface,
    CietyZoneInterface,
    CietyZoneSignatureUtils
{
    address public CIETY_MARKET_OPERATOR;

    modifier isOperator() {
        // Ensure that the caller is either the operator or the controller.
        if (msg.sender != CIETY_MARKET_OPERATOR) {
            revert InvalidOperator();
        }
        _;
    }

    constructor(address operator) {
        CIETY_MARKET_OPERATOR = operator;
    }

    /**
     * @notice            Cancel an arbitrary number of orders purposed for the sole use of operator.
     * @param seaport     The Seaport address.
     * @param orders      The orders to cancel.
     * @return cancelled  A boolean indicating whether the supplied orders have been
     *                    successfully cancelled.
     */
    function cancelOrders(
        SeaportInterface seaport,
        OrderComponents[] calldata orders
    ) external override isOperator returns (bool cancelled) {
        cancelled = seaport.cancel(orders);
    }

    // Called by Consideration whenever extraData is not provided by the caller.
    // No use for members only zone. Always returns 0xffffff which is not a magic value (= ZoneInterface.isValidOrder.selector)
    function isValidOrder(
        bytes32 orderHash,
        address caller,
        address offerer,
        bytes32 zoneHash
    ) external view returns (bytes4 validOrderMagicValue) {
        revert("Not allowed zone validation method");
    }

    /**
     * @notice                       Cancel an arbitrary number of orders.
     * @param orderHash              The hash of the members only order.
     * @param caller                 msg.sender fulfilling the members only order.
     * @param order                  Advanced order parameters
     * @param priorOrderHashes       An array of prior order hashes
     * @param criteriaResolvers      An array of proofs that supplied token identifiers
                                     to be proven by merkle tree
     * @return validOrderMagicValue  A magic value indicating that the fulfiller is
     *                               a valid member to execute the order.
     */
    function isValidOrderIncludingExtraData(
        bytes32 orderHash,
        address caller,
        AdvancedOrder calldata order,
        bytes32[] calldata priorOrderHashes,
        CriteriaResolver[] calldata criteriaResolvers
    ) external view returns (bytes4 validOrderMagicValue) {
        (bytes32 r, bytes32 vs, uint32 deadline) = _splitExtraData(
            order.extraData
        );

        if (deadline < block.timestamp) {
            revert SignatureTimeOver(caller, orderHash, deadline);
        }

        MembersOnlyExtraData
            memory _membersOnlyExtraData = MembersOnlyExtraData(
                caller,
                orderHash,
                deadline
            );

        bytes32 digest = _deriveEIP712Digest(
            _getDomainSeparator(),
            _deriveMembersOnlyHash(
                _MEMBERS_ONLY_TYPEHASH,
                _membersOnlyExtraData
            )
        );

        if (_recoverSignature(digest, r, vs) != CIETY_MARKET_OPERATOR) {
            revert MismatchSigner(caller, orderHash, deadline);
        }
        return SeaportZoneInterface.isValidOrder.selector;
    }
}