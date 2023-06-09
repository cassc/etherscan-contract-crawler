//SPDX-License-Identifier: UXUY
pragma solidity ^0.8.11;

import "./IProviderRegistry.sol";

interface IBridge is IProviderRegistry {
    struct BridgeParams {
        bytes4 providerID;
        address tokenIn;
        uint256 chainIDOut;
        address tokenOut;
        uint256 amountIn;
        uint256 minAmountOut;
        address recipient;
        bytes data;
    }

    // @dev checks if the bridge adapter supports swap between different tokens.
    function supportSwap(bytes4 providerID) external view returns (bool);

    // @dev calls bridge adapter to fulfill the exchange.
    // @return amountOut the amount of tokens transferred out, may be 0.
    // @return txnID the transaction id of the bridge, may be 0.
    function bridge(BridgeParams calldata params) external returns (uint256 amountOut, uint256 txnID);
}