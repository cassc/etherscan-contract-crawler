//SPDX-License-Identifier: UXUY
pragma solidity ^0.8.11;

import "../interfaces/bridges/IAnySwap.sol";
import "../libraries/BridgeAdapterBase.sol";
import "../interfaces/tokens/IWrappedNativeAsset.sol";
import "../libraries/SafeNativeAsset.sol";
import "../libraries/SafeERC20.sol";

contract AnySwapBridgeAdapter is BridgeAdapterBase {
    using SafeNativeAsset for address;
    using SafeERC20 for IERC20;

    address private immutable _anySwapRouter;

    constructor(address anySwapRouter) {
        _anySwapRouter = anySwapRouter;
    }

    function supportSwap() external pure returns (bool) {
        return false;
    }

    function bridge(
        BridgeParams calldata params
    ) external payable whenNotPaused onlyAllowedCaller noDelegateCall returns (uint256, uint256) {
        (address router, address anyToken, address tokenAddr) = abi.decode(params.data, (address, address, address));
        require(router == _anySwapRouter, "AnySwapBridgeAdapter: illegal router");
        address tokenIn = params.tokenIn;
        if (tokenIn.isNativeAsset()) {
            require(address(this).balance >= params.amountIn, "AnySwapBridgeAdapter: not enough native assets");
            IAnySwap(router).anySwapOutNative{value: params.amountIn}(tokenAddr, params.recipient, params.chainIDOut);
        } else {
            IERC20(tokenIn).safeApproveToMax(address(router), params.amountIn);
            if (anyToken == address(0)) {
                IAnySwap(router).anySwapOut(tokenIn, params.recipient, params.amountIn, params.chainIDOut);
            } else {
                IAnySwap(router).anySwapOutUnderlying(anyToken, params.recipient, params.amountIn, params.chainIDOut);
            }
        }
        return (0, 0);
    }
}