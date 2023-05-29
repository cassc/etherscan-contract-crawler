// SPDX-License-Identifier: Apache 2

pragma solidity ^0.8.13;

import {IWormhole} from "../interfaces/IWormhole.sol";
import {ICircleBridge} from "../interfaces/ICircleBridge.sol";
import {IMessageTransmitter} from "../interfaces/IMessageTransmitter.sol";

interface ICircleIntegration {
    struct TransferParameters {
        address token;
        uint256 amount;
        uint16 targetChain;
        bytes32 mintRecipient;
    }

    struct RedeemParameters {
        bytes encodedWormholeMessage;
        bytes circleBridgeMessage;
        bytes circleAttestation;
    }

    struct DepositWithPayload {
        bytes32 token;
        uint256 amount;
        uint32 sourceDomain;
        uint32 targetDomain;
        uint64 nonce;
        bytes32 fromAddress;
        bytes32 mintRecipient;
        bytes payload;
    }

    function transferTokensWithPayload(
        TransferParameters memory transferParams,
        uint32 batchId,
        bytes memory payload
    ) external payable returns (uint64 messageSequence);

    function redeemTokensWithPayload(
        RedeemParameters memory params
    ) external returns (DepositWithPayload memory depositWithPayload);

    function fetchLocalTokenAddress(
        uint32 sourceDomain,
        bytes32 sourceToken
    ) external view returns (bytes32);

    function encodeDepositWithPayload(DepositWithPayload memory message) external pure returns (bytes memory);

    function decodeDepositWithPayload(bytes memory encoded) external pure returns (DepositWithPayload memory message);

    function isInitialized(address impl) external view returns (bool);

    function wormhole() external view returns (IWormhole);

    function chainId() external view returns (uint16);

    function wormholeFinality() external view returns (uint8);

    function circleBridge() external view returns (ICircleBridge);

    function circleTransmitter() external view returns (IMessageTransmitter);

    function getRegisteredEmitter(uint16 emitterChainId) external view returns (bytes32);

    function isAcceptedToken(address token) external view returns (bool);

    function getDomainFromChainId(uint16 chainId_) external view returns (uint32);

    function getChainIdFromDomain(uint32 domain) external view returns (uint16);

    function isMessageConsumed(bytes32 hash) external view returns (bool);

    function localDomain() external view returns (uint32);

    function targetAcceptedToken(address sourceToken, uint16 chainId_) external view returns (bytes32);

    function verifyGovernanceMessage(bytes memory encodedMessage, uint8 action)
        external
        view
        returns (bytes32 messageHash, bytes memory payload);

    function evmChain() external view returns (uint256);

    // guardian governance only
    function updateWormholeFinality(bytes memory encodedMessage) external;

    function registerEmitterAndDomain(bytes memory encodedMessage) external;

    function registerAcceptedToken(bytes memory encodedMessage) external;

    function registerTargetChainToken(bytes memory encodedMessage) external;

    function upgradeContract(bytes memory encodedMessage) external;
}