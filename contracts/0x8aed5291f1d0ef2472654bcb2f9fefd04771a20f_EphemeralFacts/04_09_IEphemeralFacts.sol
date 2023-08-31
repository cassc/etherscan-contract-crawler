/// SPDX-License-Identifier: UNLICENSED
/// (c) Theori, Inc. 2022
/// All rights reserved

pragma solidity >=0.8.0;

import "./IRelicReceiver.sol";

interface IEphemeralFacts {
    struct ReceiverContext {
        address initiator;
        IRelicReceiver receiver;
        bytes extra;
        uint256 gasLimit;
        bool requireSuccess;
    }

    struct FactDescription {
        address account;
        bytes sigData;
    }

    event FactRequested(FactDescription desc, ReceiverContext context, uint256 bounty);

    event ReceiveSuccess(IRelicReceiver receiver, bytes32 requestId);

    event ReceiveFailure(IRelicReceiver receiver, bytes32 requestId);

    event BountyPaid(uint256 bounty, bytes32 requestId, address relayer);

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
    ) external payable;

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
    ) external payable;

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
    ) external payable;
}