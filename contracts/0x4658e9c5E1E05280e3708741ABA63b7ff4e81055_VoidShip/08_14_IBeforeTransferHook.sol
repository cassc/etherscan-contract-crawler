// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

// ERC721A-compatible
interface IBeforeTransferHook {
    function beforeTokenTransfer(
        address from,
        address to,
        uint256 startId,
        uint256 quantity
    ) external;
}