// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface I0xExchangeRouter {
    struct ZeroXTransformation {
        // The deployment nonce for the transformer.
        // The address of the transformer contract will be derived from this
        // value.
        uint32 deploymentNonce;
        // Arbitrary data to pass to the transformer.
        bytes data;
    }

    function transformERC20(
        address inputToken,
        address outputToken,
        uint256 inputTokenAmount,
        uint256 minOutputTokenAmount,
        ZeroXTransformation[] memory transformations
    ) external returns (uint256 outputTokenAmount);
}