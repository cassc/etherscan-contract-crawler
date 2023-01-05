/// SPDX-License-Identifier: UNLICENSED
/// (c) Theori, Inc. 2022
/// All rights reserved

pragma solidity >=0.8.0;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

import "./interfaces/IRelicReceiver.sol";
import "./interfaces/IReliquary.sol";
import "./interfaces/IProver.sol";
import "./interfaces/IBatchProver.sol";
import "./lib/Callbacks.sol";

/**
 * @title EphemeralFacts
 * @author Theori, Inc.
 * @notice EphemeralFacts provides delivery of ephemeral facts: facts which are
 *         passed directly to external receivers, rather than stored in the
 *         Reliquary. It also allows placing bounties on specific fact proof
 *         requests, which can be used to build a fact proving relay system.
 *         Batch provers are supported, enabling an efficient request + relay
 *         system using proof aggregation.
 */
contract EphemeralFacts {
    IReliquary immutable reliquary;

    /// @dev track the bounty associated with each fact request
    mapping(bytes32 => uint256) bounties;

    struct ReceiverContext {
        address initiator;
        IRelicReceiver receiver;
        bytes extra;
        uint256 gasLimit;
    }

    struct FactDescription {
        address account;
        bytes sigData;
    }

    event FactRequested(FactDescription desc, ReceiverContext context, uint256 bounty);

    event ReceiveSuccess(ReceiverContext context, Fact fact);

    event ReceiveFailure(ReceiverContext context, Fact fact);

    event BountyPaid(uint256 bounty, address initiator, address relayer);

    constructor(IReliquary _reliquary) {
        reliquary = _reliquary;
    }

    /**
     * @dev computes the unique requestId for this fact request, used to track bounties
     * @param account the account associated with the fact
     * @param sig the fact signature
     * @param context context about the fact receiver callback
     */
    function requestId(
        address account,
        FactSignature sig,
        ReceiverContext memory context
    ) internal pure returns (bytes32) {
        return keccak256(abi.encode(account, sig, context));
    }

    /**
     * @notice delivers the fact to the receiver, claiming any pending bounty on the request
     * @param context the contract to receive the fact
     * @param fact the fact information
     */
    function deliverFact(ReceiverContext calldata context, Fact memory fact) internal {
        bytes32 rid = requestId(fact.account, fact.sig, context);
        uint256 bounty = bounties[rid];
        require(
            context.initiator == msg.sender || bounty > 0,
            "cannot specify an initiator which didn't request the fact"
        );
        if (bounty > 0) {
            delete bounties[rid];
            emit BountyPaid(bounty, context.initiator, msg.sender);
            payable(msg.sender).transfer(bounty);
        }
        bytes memory data = abi.encodeWithSelector(
            IRelicReceiver.receiveFact.selector,
            context.initiator,
            fact,
            context.extra
        );
        if (Callbacks.callWithExactGas(context.gasLimit, address(context.receiver), data)) {
            emit ReceiveSuccess(context, fact);
        } else {
            emit ReceiveFailure(context, fact);
        }
    }

    /**
     * @notice proves a fact ephemerally and provides it to the receiver
     * @param context the ReceiverContext for delivering the fact
     * @param prover the prover module to use, must implement IProver
     * @param proof the proof to pass to the prover
     */
    function proveEphemeral(
        ReceiverContext calldata context,
        address prover,
        bytes calldata proof
    ) external payable {
        // reverts if the prover doesn't exist or is revoked
        reliquary.checkProver(reliquary.provers(prover));

        // reverts if the prover doesn't support standard interface
        require(
            IERC165(prover).supportsInterface(type(IProver).interfaceId),
            "Prover doesn't implement IProver"
        );

        Fact memory fact = IProver(prover).prove{value: msg.value}(proof, false);
        deliverFact(context, fact);
    }

    /**
     * @notice proves a batch of facts ephemerally and provides them to the receivers
     * @param contexts the ReceiverContexts for delivering the facts
     * @param prover the prover module to use, must implement IBatchProver
     * @param proof the proof to pass to the prover
     */
    function batchProveEphemeral(
        ReceiverContext[] calldata contexts,
        address prover,
        bytes calldata proof
    ) external payable {
        // reverts if the prover doesn't exist or is revoked
        reliquary.checkProver(reliquary.provers(prover));

        // reverts if the prover doesn't support standard interface
        require(
            IERC165(prover).supportsInterface(type(IBatchProver).interfaceId),
            "Prover doesn't implement IBatchProver"
        );

        Fact[] memory facts = IBatchProver(prover).proveBatch{value: msg.value}(proof, false);
        require(facts.length == contexts.length);

        for (uint256 i = 0; i < facts.length; i++) {
            deliverFact(contexts[i], facts[i]);
        }
    }

    /**
     * @notice requests a fact to be proven asynchronously and passed to the receiver,
     * @param account the account associated with the fact
     * @param sigData the fact data which determines the fact signature (class is assumed to be NO_FEE)
     * @param receiver the contract to receive the fact
     * @param data the extra data to pass to the receiver
     * @param gasLimit the maxmium gas used by the receiver
     * @dev msg.value is added to the bounty for this fact request,
     *      incentivizing somebody to prove it
     */
    function requestFact(
        address account,
        bytes calldata sigData,
        IRelicReceiver receiver,
        bytes calldata data,
        uint256 gasLimit
    ) external payable {
        FactSignature sig = Facts.toFactSignature(Facts.NO_FEE, sigData);
        ReceiverContext memory context = ReceiverContext(msg.sender, receiver, data, gasLimit);
        uint256 bounty = bounties[requestId(account, sig, context)] += msg.value;
        emit FactRequested(FactDescription(account, sigData), context, bounty);
    }
}