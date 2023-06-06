// SPDX-License-Identifier: Apache 2
pragma solidity ^0.8.17;

import "./TokenBridgeRelayerState.sol";

abstract contract TokenBridgeRelayerSetters is TokenBridgeRelayerState {
    function setOwner(address owner_) internal {
        _state.owner = owner_;
    }

    function setPendingOwner(address pendingOwner_) internal {
        _state.pendingOwner = pendingOwner_;
    }

    function setOwnerAssistant(address ownerAssistant_) internal {
        _state.ownerAssistant = ownerAssistant_;
    }

    function setFeeRecipient(address feeRecipient_) internal {
        _state.feeRecipient = feeRecipient_;
    }

    function setWormhole(address wormhole_) internal {
        _state.wormhole = payable(wormhole_);
    }

    function setTokenBridge(address tokenBridge_) internal {
        _state.tokenBridge = payable(tokenBridge_);
    }

    function setUnwrapWethFlag(bool unwrapWeth_) internal {
        _state.unwrapWeth = unwrapWeth_;
    }

    function setWethAddress(address weth_) internal {
        _state.wethAddress = weth_;
    }

    function setChainId(uint16 chainId_) internal {
        _state.chainId = chainId_;
    }

    function setPaused(bool paused) internal {
        _state.paused = paused;
    }

    function _registerContract(uint16 chainId_, bytes32 contract_) internal {
        _state.registeredContracts[chainId_] = contract_;
    }

    function setSwapRatePrecision(uint256 precision) internal {
        _state.swapRatePrecision = precision;
    }

    function setRelayerFeePrecision(uint256 precision) internal {
        _state.relayerFeePrecision = precision;
    }

    function addAcceptedToken(address token) internal {
        require(
            _state.acceptedTokens[token] == false,
            "token already registered"
        );
        _state.acceptedTokens[token] = true;
        _state.acceptedTokensList.push(token);
    }

    function removeAcceptedToken(address token) internal {
        require(
            _state.acceptedTokens[token],
            "token not registered"
        );

        // Remove the token from the acceptedTokens mapping, and
        // clear the token's swapRate and maxNativeSwapAmount.
        _state.acceptedTokens[token] = false;
        _state.swapRates[token] = 0;
        _state.maxNativeSwapAmount[token] = 0;

        // cache array length
        uint256 length_ = _state.acceptedTokensList.length;

        // Replace `token` in the acceptedTokensList with the last
        // element in the acceptedTokensList array.
        uint256 i = 0;
        for (; i < length_;) {
            if (_state.acceptedTokensList[i] == token) {
                break;
            }
            unchecked { i += 1; }
        }

        if (i != length_) {
            if (length_ > 1) {
                _state.acceptedTokensList[i] = _state.acceptedTokensList[length_ - 1];
            }
            _state.acceptedTokensList.pop();
        }
    }

    function setRelayerFee(uint16 chainId_, uint256 fee) internal {
        _state.relayerFees[chainId_] = fee;
    }

    function setSwapRate(address token, uint256 swapRate) internal {
        _state.swapRates[token] = swapRate;
    }

    function setMaxNativeSwapAmount(address token, uint256 maximum) internal {
        _state.maxNativeSwapAmount[token] = maximum;
    }
}