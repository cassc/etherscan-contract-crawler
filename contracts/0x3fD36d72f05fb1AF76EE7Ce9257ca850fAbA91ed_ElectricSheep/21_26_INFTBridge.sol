// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

interface INFTBridge {
    function sendMsg(
        uint64 chainId,
        address sender,
        address receiver,
        uint256 tokenId,
        string calldata uri
    ) external payable;

    function sendMsg(
        uint64 chainId,
        address sender,
        bytes calldata receiver,
        uint256 tokenId,
        string calldata uri
    ) external payable;

    function totalFee(
        uint64 chainId,
        address nft,
        uint256 tokenId
    ) external view returns (uint256);
}