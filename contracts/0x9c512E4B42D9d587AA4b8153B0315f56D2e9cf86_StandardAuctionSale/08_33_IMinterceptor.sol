// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.11;

interface IMinterceptor {
    function mintByUri(
        uint256 voucherId,
        address collectionContract,
        uint256 itemId,
        address to,
        string calldata uri,
        bytes calldata data
    ) external payable;
}