// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.11;

struct MintEditionsParams {
    uint256 voucherId;
    uint256 itemId;
    uint256 quantity;
    address to;
    address collection;
}

interface IMinterceptor {
    function mintByUri(
        uint256 voucherId,
        address collectionContract,
        uint256 itemId,
        address to,
        string calldata uri,
        bytes calldata data
    ) external payable;

    function mintEditions(
        MintEditionsParams calldata mintParams,
        bytes calldata data
    ) external payable;

    function mintEditions(
        MintEditionsParams calldata mintParams,
        string calldata uri,
        bytes calldata data
    ) external payable;
}