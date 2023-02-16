// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IPadi1155 {
    struct MintAssetRequest {
        address requester;
        uint256 assetId;
        uint256 amount;
        uint256 nonce;
    }

    function safeMint(
        string memory _ipfs,
        bytes calldata _signature,
        MintAssetRequest calldata _req
    ) external payable;
}