// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

interface IArkenDexAmbassador {
    function tradeWithTarget(
        address srcToken,
        address dstToken,
        uint256 amountIn,
        bytes calldata interactionDataOutside,
        address targetOutside
    ) external payable;
}