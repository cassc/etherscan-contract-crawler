// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

interface IAcross {
    function deposit(
        address recipient,
        address originToken,
        uint256 amount,
        uint256 destinationChainId,
        uint64 relayerFeePct,
        uint32 quoteTimestamp
    ) external payable;
}