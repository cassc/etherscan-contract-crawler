// SPDX-License-Identifier: Apache 2
pragma solidity ^0.8.17;

import "./CircleRelayerState.sol";

contract CircleRelayerSetters is CircleRelayerState {
    function setOwner(address owner_) internal {
        _state.owner = owner_;
    }

    function setPendingOwner(address pendingOwner_) internal {
        _state.pendingOwner = pendingOwner_;
    }

    function setOwnerAssistant(address ownerAssistant_) internal {
        _state.ownerAssistant = ownerAssistant_;
    }

    function setPaused(bool paused) internal {
        _state.paused = paused;
    }

    function setWormhole(address wormhole_) internal {
        _state.wormhole = payable(wormhole_);
    }

    function setChainId(uint16 chainId_) internal {
        _state.chainId = chainId_;
    }

    function setNativeTokenDecimals(uint8 decimals_) internal {
        _state.nativeTokenDecimals = decimals_;
    }

    function setCircleIntegration(address circleIntegration_) internal {
        _state.circleIntegration = circleIntegration_;
    }

    function setFeeRecipient(address feeRecipient_) internal {
        _state.feeRecipient = feeRecipient_;
    }

    function setRelayerFee(uint16 chainId_, address token, uint256 fee) internal {
        _state.relayerFees[chainId_][token] = fee;
    }

    function setNativeSwapRatePrecision(uint256 precision) internal {
        _state.nativeSwapRatePrecision = precision;
    }

    function setNativeSwapRate(address token, uint256 swapRate) internal {
        _state.nativeSwapRates[token] = swapRate;
    }

    function setMaxNativeSwapAmount(address token, uint256 maximum) internal {
        _state.maxNativeSwapAmount[token] = maximum;
    }

    function _registerContract(uint16 chainId_, bytes32 contract_) internal {
        _state.registeredContracts[chainId_] = contract_;
    }
}