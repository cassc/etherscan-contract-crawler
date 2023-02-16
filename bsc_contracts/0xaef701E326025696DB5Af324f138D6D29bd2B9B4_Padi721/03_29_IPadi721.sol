// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

//@dev Only use for nft because it has offer functions
interface IPadi721 {
    struct MintAssetRequest {
        address requester;
        uint256 assetId;
        uint256 nonce;
    }

    function safeMint(
        string memory _ipfs,
        bytes calldata _signature,
        MintAssetRequest calldata _req
    ) external payable;

    function claim(
        address _to,
        string memory _ipfs
    ) external;
}