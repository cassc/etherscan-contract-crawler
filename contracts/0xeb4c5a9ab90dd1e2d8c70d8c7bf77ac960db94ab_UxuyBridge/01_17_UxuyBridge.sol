//SPDX-License-Identifier: UXUY
pragma solidity ^0.8.11;

import "./libraries/BrokerBase.sol";
import "./interfaces/IBridge.sol";
import "./interfaces/IBridgeAdapter.sol";

contract UxuyBridge is IBridge, BrokerBase {
    function supportSwap(bytes4 providerID) external view returns (bool) {
        return _getAdapter(providerID).supportSwap();
    }

    function bridge(
        BridgeParams calldata params
    ) external whenNotPaused onlyAllowedCaller noDelegateCall returns (uint256, uint256) {
        return
            _getAdapter(params.providerID).bridge(
                IBridgeAdapter.BridgeParams({
                    tokenIn: params.tokenIn,
                    chainIDOut: params.chainIDOut,
                    tokenOut: params.tokenOut,
                    amountIn: params.amountIn,
                    minAmountOut: params.minAmountOut,
                    recipient: params.recipient,
                    data: params.data
                })
            );
    }

    function _getAdapter(bytes4 providerID) internal view returns (IBridgeAdapter) {
        address provider = _getProvider(providerID);
        require(provider != address(0), "UxuyBridge: provider not found");
        return IBridgeAdapter(provider);
    }
}