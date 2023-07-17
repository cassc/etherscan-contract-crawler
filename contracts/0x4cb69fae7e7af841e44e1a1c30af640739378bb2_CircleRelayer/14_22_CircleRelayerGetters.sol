// SPDX-License-Identifier: Apache 2
pragma solidity ^0.8.17;

import {IWormhole} from "../interfaces/IWormhole.sol";
import {ICircleIntegration} from "../interfaces/ICircleIntegration.sol";

import "./CircleRelayerSetters.sol";

contract CircleRelayerGetters is CircleRelayerSetters {
    function owner() public view returns (address) {
        return _state.owner;
    }

    function pendingOwner() public view returns (address) {
        return _state.pendingOwner;
    }

    function ownerAssistant() public view returns (address) {
        return _state.ownerAssistant;
    }

    function wormhole() public view returns (IWormhole) {
        return IWormhole(_state.wormhole);
    }

    /**
     * @return paused If true, requests for token transfers will be blocked and no circle transfer VAAs will be generated.
     */
    function getPaused() public view returns (bool paused) {
        paused = _state.paused;
    }

    function chainId() public view returns (uint16) {
        return _state.chainId;
    }

    function nativeTokenDecimals() public view returns (uint8) {
        return _state.nativeTokenDecimals;
    }

    function circleIntegration() public view returns (ICircleIntegration) {
        return ICircleIntegration(_state.circleIntegration);
    }

    function feeRecipient() public view returns (address) {
        return _state.feeRecipient;
    }

    function relayerFee(uint16 chainId_, address token) public view returns (uint256) {
        return _state.relayerFees[chainId_][token];
    }

    function nativeSwapRatePrecision() public view returns (uint256) {
        return _state.nativeSwapRatePrecision;
    }

    function nativeSwapRate(address token) public view returns (uint256) {
        return _state.nativeSwapRates[token];
    }

    function maxNativeSwapAmount(address token) public view returns (uint256) {
        return _state.maxNativeSwapAmount[token];
    }

    function getRegisteredContract(uint16 emitterChainId) public view returns (bytes32) {
        return _state.registeredContracts[emitterChainId];
    }
}