// SPDX-License-Identifier: UNLICENSED
// Copyright (c) Eywa.Fi, 2021-2023 - all rights reserved
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "../interfaces/IBridgeV2.sol";
import "../utils/Block.sol";
import "../utils/Bls.sol";
import "../utils/Merkle.sol";
import "../utils/RequestIdChecker.sol";
import "../utils/Typecast.sol";


contract BridgeV2 is IBridgeV2, AccessControlEnumerable, Typecast, ReentrancyGuard {
    
    using Address for address;
    using Bls for Bls.Epoch;

    /// @dev gate keeper role id
    bytes32 public constant GATEKEEPER_ROLE = keccak256("GATEKEEPER_ROLE");
    /// @dev validator role id
    bytes32 public constant VALIDATOR_ROLE = keccak256("VALIDATOR_ROLE");
    /// @dev operator role id
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

    /// @dev human readable version
    string public version;
    /// @dev current state Active\Inactive
    State public state;
    /// @dev nonces
    mapping(address => uint256) public nonces;
    /// @dev received request IDs against relay
    RequestIdChecker public currentRequestIdChecker;
    /// @dev received request IDs against relay
    RequestIdChecker public previousRequestIdChecker;
    // current epoch
    Bls.Epoch internal currentEpoch;
    // previous epoch
    Bls.Epoch internal previousEpoch;

    event EpochUpdated(bytes key, uint32 epochNum, uint64 protocolVersion);

    event RequestSent(
        bytes32 requestId,
        bytes data,
        address to,
        uint64 chainIdTo
    );

    event RequestReceived(bytes32 requestId, string error);

    event StateSet(State state);

    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        version = "2.2.3";
        currentRequestIdChecker = new RequestIdChecker();
        previousRequestIdChecker = new RequestIdChecker();
        state = State.Inactive;
    }

    /**
     * @dev Get current epoch.
     */
    function getCurrentEpoch() public view returns (bytes memory, uint8, uint32) {
        return (abi.encode(currentEpoch.publicKey), currentEpoch.participantsCount, currentEpoch.epochNum);
    }

    /**
     * @dev Get previous epoch.
     */
    function getPreviousEpoch() public view returns (bytes memory, uint8, uint32) {
        return (abi.encode(previousEpoch.publicKey), previousEpoch.participantsCount, previousEpoch.epochNum);
    }

    /**
     * @dev Updates current epoch.
     *
     * @param params ReceiveParams struct.
     */
    function updateEpoch(ReceiveParams calldata params) external onlyRole(VALIDATOR_ROLE) {
        // TODO ensure that new epoch really next one after previous (by hash)
        bytes memory payload = Merkle.prove(params.merkleProof, Block.txRootHash(params.blockHeader));
        (uint64 newEpochProtocolVersion, uint32 newEpochNum, bytes memory newKey, uint8 newParticipantsCount) = Block
            .decodeEpochUpdate(payload);

        require(currentEpoch.epochNum + 1 == newEpochNum, "Bridge: wrong epoch number");
    
        // TODO remove if when resetEpoch will be removed
        if (currentEpoch.isSet()) {
            verifyEpoch(currentEpoch, params);
            rotateEpoch();
        }

        // TODO ensure that new epoch really next one after previous (prev hash + params.blockHeader)
        bytes32 newHash = sha256(params.blockHeader);
        currentEpoch.update(newKey, newParticipantsCount, newEpochNum, newHash);

        onEpochStart(newEpochProtocolVersion);
    }

    /**
     * @dev Forcefully reset epoch on all chains.
     */
    function resetEpoch() public onlyRole(OPERATOR_ROLE) {
        // TODO consider to remove any possible manipulations from protocol
        if (currentEpoch.isSet()) {
            rotateEpoch();
            currentEpoch.epochNum = previousEpoch.epochNum + 1;
        } else {
            currentEpoch.epochNum = currentEpoch.epochNum + 1;
        }
        onEpochStart(0);
    }

    /**
     * @dev Send crosschain request v2.
     *
     * @param params struct with requestId, data, receiver and opposite cahinId
     * @param from sender's address
     * @param nonce sender's nonce
     */
    function sendV2(
        SendParams calldata params,
        address from,
        uint256 nonce
    ) external override onlyRole(GATEKEEPER_ROLE) returns (bool) {
        require(state == State.Active, "Bridge: state inactive");
        require(previousEpoch.isSet() || currentEpoch.isSet(), "Bridge: epoch not set");
    
        verifyAndUpdateNonce(from, nonce);

        emit RequestSent(
            params.requestId,
            params.data,
            params.to,
            uint64(params.chainIdTo)
        );

        return true;
    }

    /**
     * @dev Receive (batch) crosschain request v2.
     *
     * @param params array with ReceiveParams structs.
     */
    function receiveV2(ReceiveParams[] calldata params) external override onlyRole(VALIDATOR_ROLE) nonReentrant returns (bool) {
        require(state != State.Inactive, "Bridge: state inactive");

        for (uint256 i = 0; i < params.length; ++i) {
            bytes32 epochHash = Block.epochHash(params[i].blockHeader);

            // verify the block signature
            if (epochHash == currentEpoch.epochHash) {
                require(currentEpoch.isSet(), "Bridge: epoch not set");
                verifyEpoch(currentEpoch, params[i]);
            } else if (epochHash == previousEpoch.epochHash) {
                require(previousEpoch.isSet(), "Bridge: epoch not set");
                verifyEpoch(previousEpoch, params[i]);
            } else {
                revert("Bridge: wrong epoch");
            }

            // verify that the transaction is really in the block
            bytes memory payload = Merkle.prove(params[i].merkleProof, Block.txRootHash(params[i].blockHeader));

            // get call data
            (bytes32 requestId, bytes memory receivedData, address to, uint64 chainIdTo) = Block.decodeRequest(payload);
            require(chainIdTo == block.chainid, "Bridge: wrong chain id");

            require(to.isContract(), "Bridge: receiver is not a contract");

            bool isRequestIdUniq;
            if (epochHash == currentEpoch.epochHash) {
                isRequestIdUniq = currentRequestIdChecker.check(requestId);
            } else {
                isRequestIdUniq = previousRequestIdChecker.check(requestId);
            }

            string memory err;
            
            if (isRequestIdUniq) {
                (bytes memory data, bytes memory check) = abi.decode(receivedData, (bytes, bytes));
                bytes memory result = to.functionCall(check);
                require(abi.decode(result, (bool)), "Bridge: check failed");
                
                to.functionCall(data, "Bridge: receive failed");
            } else {
                revert("Bridge: request id already seen");
            }

            emit RequestReceived(requestId, err);
        }

        return true;
    }

    /**
     * @dev Set new state.
     *
     * @param state_ Active\Inactive state
     */
    function setState(State state_) external onlyRole(OPERATOR_ROLE) {
        state = state_;
        emit StateSet(state);
    }

    /**
     * @dev Verifies epoch.
     *
     * @param epoch current or previous epoch;
     * @param params oracle tx params
     */
    function verifyEpoch(Bls.Epoch storage epoch, ReceiveParams calldata params) internal view {
        Block.verify(
            epoch,
            params.blockHeader,
            params.votersPubKey,
            params.votersSignature,
            params.votersMask
        );
    }

    /**
     * @dev Verifies and updates the sender's nonce.
     *
     * @param from sender's address
     * @param nonce provided nonce
     */
    function verifyAndUpdateNonce(address from, uint256 nonce) internal {
        require(nonces[from]++ == nonce, "Bridge: nonce mismatch");
    }

    /**
     * @dev Moves current epoch and current request filter to previous.
     */
    function rotateEpoch() internal {
        previousEpoch = currentEpoch;
        Bls.Epoch memory epoch;
        currentEpoch = epoch;
        previousRequestIdChecker.destroy();
        previousRequestIdChecker = currentRequestIdChecker;
        currentRequestIdChecker = new RequestIdChecker();
    }

    /**
     * @dev Hook on start new epoch.
     */
    function onEpochStart(uint64 protocolVersion_) internal virtual {
        emit EpochUpdated(abi.encode(currentEpoch.publicKey), currentEpoch.epochNum, protocolVersion_);
    }
}